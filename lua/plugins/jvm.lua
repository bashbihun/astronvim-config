-- lua/plugins/jvm.lua
-- Java / Kotlin / Spring Boot.
--
-- Pembagian tugas:
--   * Java   : astrocommunity.pack.java (di lua/community.lua) -> jdtls + nvim-jdtls
--              + java-debug-adapter + java-test + lemminx (XML/pom.xml)
--   * Kotlin : kotlin-language-server + ktlint (diatur di file ini)
--   * Spring : generator project (Spring Initializr API) + runner bootRun/mvn
--   * Test   : neotest-gradle (Java/Kotlin Gradle) -> lihat testing.lua,
--              plus test per-method/class Java via jdtls (Maven juga bisa)
--
-- Prasyarat di sistem (TIDAK diinstall Mason):
--   JDK 17+ (disarankan lewat SDKMAN: `sdk install java 21-tem`), `curl`, `unzip`,
--   dan (opsional) `gradle` / `mvn` global buat project non-Spring.
--   Project Spring Initializr sudah bawa `mvnw`/`gradlew`, jadi cukup JDK.
--
-- Keymap (<leader>J):
--   Jn  Buat project Spring Boot baru (Java/Kotlin, Maven/Gradle)
--   Jg  Buat project polos tanpa Spring (Maven ATAU Gradle, Java/Kotlin)
--   Jr  Run (Spring: bootRun / spring-boot:run; non-Spring: gradle run / mvn exec:java)
--   Jb  Build        Jt  Test semua      Jc  Clean
--   Jf  Test class file aktif   (Maven & Gradle, Java & Kotlin, via CLI)
--   JM  Test method di bawah cursor (taruh cursor di nama method test)
--   Jm  Test method terdekat (Java, via jdtls)   Jk  Test class (Java, via jdtls)
--   Jo  Organize imports (Java, via jdtls)
--
-- Project polos TANPA Maven/Gradle (folder src/ lib/ bin/): tetap didukung. Runner/test
-- jalan dari ROOT project (tidak masuk ke bin/); bin/ hanya output .class. Test butuh
-- lib/junit-platform-console-standalone-<versi>.jar. (Linux/macOS)
--
-- Build tool terdeteksi otomatis (gradlew/build.gradle(.kts) atau mvnw/pom.xml).
-- Kalau project punya dua-duanya, Gradle diprioritaskan. Paksa pilihan dengan:
--   :let g:jvm_build_tool = "maven"   (atau "gradle")

local function ask(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default }, function(v)
    if v == nil then return vim.notify("Dibatalkan", vim.log.levels.WARN) end
    cb(v ~= "" and v or default)
  end)
end

local function pick(prompt, items, cb)
  vim.ui.select(items, { prompt = prompt }, function(choice)
    if not choice then return vim.notify("Dibatalkan", vim.log.levels.WARN) end
    cb(choice)
  end)
end

local function root_cmd()
  local cwd = vim.fn.getcwd()
  local function has(f) return vim.fn.filereadable(cwd .. "/" .. f) == 1 end
  local gradle = has "gradlew" and "./gradlew" or ((has "build.gradle.kts" or has "build.gradle") and "gradle" or nil)
  local maven = has "mvnw" and "./mvnw" or (has "pom.xml" and "mvn" or nil)
  local pref = vim.g.jvm_build_tool
  if pref == "maven" and maven then return maven, "maven" end
  if pref == "gradle" and gradle then return gradle, "gradle" end
  if gradle then return gradle, "gradle" end
  if maven then return maven, "maven" end
end

local function is_spring()
  local cwd = vim.fn.getcwd()
  for _, f in ipairs { "build.gradle.kts", "build.gradle", "pom.xml" } do
    local path = cwd .. "/" .. f
    if vim.fn.filereadable(path) == 1 and table.concat(vim.fn.readfile(path), "\n"):find("spring%-boot") then
      return true
    end
  end
  return false
end

local function run_in_term(cmd, count)
  require("toggleterm").exec(cmd, count, nil, nil, "horizontal")
end

-- tebak nama class lengkap dari buffer aktif (package + nama file; Kotlin top-level -> XxxKt)
local function current_fqcn()
  local name = vim.fn.expand "%:t:r"
  if vim.fn.expand "%:e" == "kt" then name = name .. "Kt" end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 30, false)) do
    local pkg = line:match "^package%s+([%w%._]+)"
    if pkg then return pkg .. "." .. name end
  end
  return name
end

-- ---------- project polos tanpa Maven/Gradle: src/ lib/ bin/ ----------
-- Alur: kompilasi semua source (src/, dan test/ kalau ada) ke bin/, classpath = bin + semua jar di lib/.
-- Perintah SELALU jalan dari root project (cwd tidak pernah pindah ke bin/); bin/ hanya folder output.
local sep = vim.fn.has "win32" == 1 and ";" or ":"

local function plain_root()
  if vim.fn.isdirectory(vim.fn.getcwd() .. "/src") == 1 then return true end
end

local function plain_cp()
  local jars = vim.fn.globpath(vim.fn.getcwd() .. "/lib", "**/*.jar", false, true)
  local list = { "bin" }
  for _, j in ipairs(jars) do table.insert(list, vim.fn.fnamemodify(j, ":.")) end
  return vim.fn.shellescape(table.concat(list, sep))
end

local function plain_compile()
  local cwd, cp = vim.fn.getcwd(), plain_cp()
  local dirs = { "src" }
  if vim.fn.isdirectory(cwd .. "/test") == 1 then table.insert(dirs, "test") end
  local dl = table.concat(dirs, " ")
  local function has(ext)
    for _, d in ipairs(dirs) do
      if #vim.fn.globpath(cwd .. "/" .. d, "**/*." .. ext, false, true) > 0 then return true end
    end
  end
  local parts = { "mkdir -p bin" }
  if has "kt" then table.insert(parts, "kotlinc -d bin -cp " .. cp .. " " .. dl) end
  if has "java" then table.insert(parts, "javac -d bin -cp " .. cp .. " $(find " .. dl .. " -name '*.java')") end
  -- salin resource (application.properties/yml, template, dll) dari src/ dan resources/ ke bin/
  -- supaya ikut ada di classpath (penting buat Spring Boot); dibungkus sh -c biar aman di fish/zsh/bash
  local copy = [[find src -type f ! -name "*.java" ! -name "*.kt" | while read -r f; do d="bin/${f#src/}"; mkdir -p "$(dirname "$d")"; cp "$f" "$d"; done; if [ -d resources ]; then cp -R resources/. bin/; fi]]
  table.insert(parts, "sh -c " .. vim.fn.shellescape(copy))
  return table.concat(parts, " && ")
end

local function plain_launcher()
  return vim.fn.expand "%:e" == "kt" and "kotlin" or "java"
end

local function junit_jar()
  local jars = vim.fn.glob(vim.fn.getcwd() .. "/lib/junit-platform-console-standalone*.jar", false, true)
  if jars[1] then return vim.fn.fnamemodify(jars[1], ":.") end
  vim.notify(
    "Taruh junit-platform-console-standalone-<versi>.jar (1.10+) di folder lib/ untuk menjalankan test.",
    vim.log.levels.WARN
  )
end

-- select: nil = semua test di bin/, atau "class" / "method"
local function plain_test(select)
  local jar = junit_jar()
  if not jar then return end
  local cmd = string.format("%s && java -jar %s execute -cp %s ", plain_compile(), jar, plain_cp())
  if select == "class" then
    cmd = cmd .. "--select-class " .. current_fqcn()
  elseif select == "method" then
    cmd = cmd .. "--select-method " .. vim.fn.shellescape(current_fqcn() .. "#" .. vim.fn.expand "<cword>")
  else
    cmd = cmd .. "--scan-classpath bin"
  end
  run_in_term(cmd)
end

local function plain_action(action)
  if action == "run" then
    return ask("Main class: ", current_fqcn(), function(main)
      run_in_term(string.format("%s && %s -cp %s %s", plain_compile(), plain_launcher(), plain_cp(), main), 9)
    end)
  elseif action == "build" then
    return run_in_term(plain_compile())
  elseif action == "test" then
    return plain_test()
  elseif action == "clean" then
    return run_in_term "rm -rf bin"
  end
end

local function build_action(action)
  local tool, kind = root_cmd()
  if not tool and plain_root() then return plain_action(action) end
  -- tanpa src/ dan tanpa build tool: run file .java/.kt aktif saja, output .class ke bin/ (classpath: bin + lib/*.jar)
  local ft = vim.bo.filetype
  if not tool and action == "run" and (ft == "java" or ft == "kotlin") then
    local cp, file = plain_cp(), vim.fn.shellescape(vim.fn.expand "%:p")
    local compile = (ft == "kotlin" and "kotlinc" or "javac") .. " -d bin -cp " .. cp .. " " .. file
    return run_in_term(
      string.format("mkdir -p bin && %s && %s -cp %s %s", compile, plain_launcher(), cp, current_fqcn()), 9
    )
  end
  if not tool then
    return vim.notify("Tidak ketemu pom.xml / build.gradle / folder src di " .. vim.fn.getcwd(), vim.log.levels.WARN)
  end
  local spring = is_spring()
  if action == "run" then
    if kind == "gradle" then
      return run_in_term(tool .. (spring and " bootRun" or " run"), 9)
    elseif spring then
      return run_in_term(tool .. " spring-boot:run", 9)
    end
    -- Maven non-Spring: butuh main class (exec-maven-plugin dipanggil langsung, tanpa edit pom.xml)
    return ask("Main class: ", current_fqcn(), function(main)
      run_in_term(string.format("%s -q compile exec:java -Dexec.mainClass=%s", tool, vim.fn.shellescape(main)), 9)
    end)
  end
  local map = {
    gradle = { build = "build", test = "test", clean = "clean" },
    maven = { build = "package", test = "test", clean = "clean" },
  }
  run_in_term(tool .. " " .. map[kind][action])
end

-- test 1 class (file aktif) atau 1 method (nama di bawah cursor) lewat CLI
-- -> jalan untuk Maven & Gradle, Java & Kotlin
local function test_target(method)
  local tool, kind = root_cmd()
  if not tool and plain_root() then return plain_test(method and "method" or "class") end
  if not tool then
    return vim.notify("Tidak ketemu pom.xml / build.gradle di " .. vim.fn.getcwd(), vim.log.levels.WARN)
  end
  local class = vim.fn.expand "%:t:r"
  if class == "" then return end
  local m = method and vim.fn.expand "<cword>" or nil
  local cmd
  if kind == "maven" then
    local sel = class .. (m and ("#" .. m) or "")
    cmd = string.format("%s test -Dtest=%s -Dsurefire.failIfNoSpecifiedTests=false", tool, vim.fn.shellescape(sel))
  else
    local sel = "*" .. class .. (m and ("." .. m) or "")
    cmd = string.format("%s test --tests %s", tool, vim.fn.shellescape(sel))
  end
  run_in_term(cmd)
end

-- ---------- generator ----------
local function open_project(dest)
  vim.cmd("cd " .. vim.fn.fnameescape(dest))
  -- buka file main (xxxApplication.java/kt atau Main/App) biar jdtls/kotlin-ls langsung start
  local found = {}
  for _, pat in ipairs { "**/*Application.*", "**/Main.*", "**/App.*" } do
    found = vim.fn.globpath(dest .. "/src", pat, false, true)
    if #found > 0 then break end
  end
  if found[1] then vim.cmd("edit " .. vim.fn.fnameescape(found[1])) end
  pcall(vim.cmd, "Neotree show")
  vim.notify("Project siap: " .. dest)
end

local function finish(dest)
  vim.system({ "git", "init", "-q" }, { cwd = dest }):wait() -- jdtls butuh root marker (.git/mvnw/gradlew)
  vim.schedule(function() open_project(dest) end)
end

local function spring_new()
  pick("Build tool:", { "gradle-project-kotlin", "gradle-project", "maven-project" }, function(btype)
    pick("Bahasa:", { "java", "kotlin" }, function(lang)
      ask("Group ID: ", "com.example", function(group)
        ask("Artifact ID (nama project): ", "demo", function(artifact)
          pick("Java version:", { "21", "17", "25" }, function(jv)
            ask("Dependencies (pisah koma): ", "web,data-jpa,validation,devtools", function(deps)
              ask("Simpan di folder: ", vim.fn.getcwd(), function(parent)
                parent = vim.fn.expand(parent)
                local dest = parent .. "/" .. artifact
                if vim.fn.isdirectory(dest) == 1 then
                  return vim.notify(dest .. " sudah ada", vim.log.levels.ERROR)
                end
                vim.fn.mkdir(dest, "p")
                local zip = vim.fn.tempname() .. ".zip"
                vim.notify("Download dari start.spring.io ...")
                vim.system({
                  "curl", "-fsSL", "https://start.spring.io/starter.zip", "-o", zip,
                  "-d", "type=" .. btype, "-d", "language=" .. lang,
                  "-d", "groupId=" .. group, "-d", "artifactId=" .. artifact,
                  "-d", "name=" .. artifact, "-d", "javaVersion=" .. jv,
                  "-d", "dependencies=" .. deps,
                }, { text = true }, function(res)
                  if res.code ~= 0 then
                    return vim.schedule(function()
                      vim.notify("curl gagal: " .. (res.stderr or ""), vim.log.levels.ERROR)
                    end)
                  end
                  local un = vim.system({ "unzip", "-q", zip, "-d", dest }, { text = true }):wait()
                  if un.code ~= 0 then
                    return vim.schedule(function()
                      vim.notify("unzip gagal: " .. (un.stderr or ""), vim.log.levels.ERROR)
                    end)
                  end
                  vim.system({ "chmod", "+x", dest .. "/mvnw", dest .. "/gradlew" }):wait()
                  -- neotest-java compile via jdtls: simpan nama parameter di bytecode (-parameters),
                  -- kalau tidak, test Spring (@WebMvcTest/@MockBean) bisa gagal "parameter name information not available"
                  if lang == "java" then
                    vim.fn.mkdir(dest .. "/.settings", "p")
                    vim.fn.writefile({
                      "eclipse.preferences.version=1",
                      "org.eclipse.jdt.core.compiler.codegen.methodParameters=generate",
                    }, dest .. "/.settings/org.eclipse.jdt.core.prefs")
                  end
                  finish(dest)
                end)
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

local function gradle_init(dest, ptype, name, pkg)
  if vim.fn.executable "gradle" ~= 1 then
    return vim.notify("`gradle` belum terinstall (SDKMAN: sdk install gradle)", vim.log.levels.ERROR)
  end
  vim.notify("gradle init ... (tunggu, bisa agak lama)")
  vim.system({
    "gradle", "init", "--type", ptype, "--dsl", "kotlin",
    "--test-framework", "junit-jupiter", "--project-name", name,
    "--package", pkg, "--use-defaults", "--no-incubating",
  }, { cwd = dest, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return vim.notify("gradle init gagal:\n" .. (res.stderr or res.stdout or ""), vim.log.levels.ERROR)
      end
      finish(dest)
    end)
  end)
end

local function maven_init(parent, lang, group, artifact)
  if vim.fn.executable "mvn" ~= 1 then
    return vim.notify("`mvn` belum terinstall (SDKMAN: sdk install maven)", vim.log.levels.ERROR)
  end
  local args = { "mvn", "-B", "archetype:generate", "-DgroupId=" .. group, "-DartifactId=" .. artifact,
    "-Dversion=1.0-SNAPSHOT", "-DinteractiveMode=false" }
  if lang == "kotlin" then
    vim.list_extend(args, { "-DarchetypeGroupId=org.jetbrains.kotlin", "-DarchetypeArtifactId=kotlin-archetype-jvm" })
  else
    vim.list_extend(args, { "-DarchetypeGroupId=org.apache.maven.archetypes", "-DarchetypeArtifactId=maven-archetype-quickstart" })
  end
  vim.notify("mvn archetype:generate ... (tunggu, download archetype)")
  vim.system(args, { cwd = parent, text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return vim.notify("mvn archetype gagal:\n" .. (res.stdout or "") .. (res.stderr or ""), vim.log.levels.ERROR)
      end
      finish(parent .. "/" .. artifact)
    end)
  end)
end

-- project polos manual: src/ lib/ bin/ (tanpa build tool, kompilasi pakai javac/kotlinc)
local function plain_init(dest, lang, group, name)
  local pkgdir = dest .. "/src/" .. (group:gsub("%.", "/"))
  vim.fn.mkdir(pkgdir, "p")
  vim.fn.mkdir(dest .. "/lib", "p")
  vim.fn.mkdir(dest .. "/bin", "p")
  if lang == "kotlin" then
    vim.fn.writefile({ "package " .. group, "", "fun main() {", '    println("Hello, ' .. name .. '!")', "}" }, pkgdir .. "/Main.kt")
  else
    vim.fn.writefile({
      "package " .. group .. ";", "", "public class Main {",
      "    public static void main(String[] args) {",
      '        System.out.println("Hello, ' .. name .. '!");', "    }", "}",
    }, pkgdir .. "/Main.java")
  end
  vim.fn.writefile({ "bin/" }, dest .. "/.gitignore")
  finish(dest)
end

-- project polos (tanpa Spring): pilih Maven ATAU Gradle
local function project_new()
  pick("Build tool:", { "gradle", "maven", "plain (src/lib/bin, tanpa build tool)" }, function(tool)
    pick("Bahasa:", { "java", "kotlin" }, function(lang)
      ask("Group / package: ", "com.example", function(group)
        ask("Nama project: ", "myapp", function(name)
          ask("Simpan di folder: ", vim.fn.getcwd(), function(parent)
            parent = vim.fn.expand(parent)
            local dest = parent .. "/" .. name
            if vim.fn.isdirectory(dest) == 1 then
              return vim.notify(dest .. " sudah ada", vim.log.levels.ERROR)
            end
            if tool == "maven" then
              return maven_init(parent, lang, group, name)
            end
            if tool:find "^plain" then
              vim.fn.mkdir(dest, "p")
              return plain_init(dest, lang, group, name)
            end
            pick("Tipe:", { "application", "library" }, function(kind)
              vim.fn.mkdir(dest, "p")
              gradle_init(dest, lang .. "-" .. kind, name, group)
            end)
          end)
        end)
      end)
    end)
  end)
end

local function jdtls_call(fn)
  return function()
    local ok, jdtls = pcall(require, "jdtls")
    if ok and jdtls[fn] then
      jdtls[fn]()
    else
      vim.notify("jdtls belum aktif (buka file .java di dalam project dulu)", vim.log.levels.WARN)
    end
  end
end

return {
  -- jdtls untuk project polos src/lib/bin (diabaikan kalau project pakai Maven/Gradle)
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = {
      settings = {
        java = {
          project = {
            sourcePaths = { "src" },
            outputPath = "bin",
            referencedLibraries = { "lib/**/*.jar" },
          },
        },
      },
    },
  },

  -- Kotlin: LSP + formatter
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = { ensure_installed = { "kotlin-language-server", "ktlint" } },
  },
  {
    "AstroNvim/astrolsp",
    opts = {
      config = {
        -- root project sudah dideteksi default (settings.gradle(.kts), build.gradle(.kts), pom.xml)
        -- Gradle project: pertama kali lambat (resolve classpath), tunggu sebentar
        kotlin_language_server = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { kotlin = { "ktlint" } } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "java", "kotlin", "properties", "xml",
      })
      return opts
    end,
  },

  -- Keymap + command
  {
    "AstroNvim/astrocore",
    opts = {
      commands = {
        SpringNew = { spring_new, desc = "Buat project Spring Boot (Initializr)" },
        JvmRun = { function() build_action "run" end, desc = "Run Java/Kotlin/Spring (Maven/Gradle/polos)" },
        ProjectNew = { project_new, desc = "Buat project Java/Kotlin polos (Maven/Gradle)" },
      },
      mappings = {
        n = {
          ["<Leader>J"] = { desc = " Java / Kotlin / Spring" },
          ["<Leader>Jn"] = { spring_new, desc = "New Spring Boot project" },
          ["<Leader>Jg"] = { project_new, desc = "New project Maven/Gradle (non-Spring)" },
          ["<Leader>Jr"] = { function() build_action "run" end, desc = "Run (Spring/plain, Maven/Gradle)" },
          ["<Leader>Jb"] = { function() build_action "build" end, desc = "Build" },
          ["<Leader>Jt"] = { function() build_action "test" end, desc = "Test semua (CLI)" },
          ["<Leader>Jc"] = { function() build_action "clean" end, desc = "Clean" },
          ["<Leader>Jf"] = { function() test_target(false) end, desc = "Test class file aktif (Maven/Gradle)" },
          ["<Leader>JM"] = { function() test_target(true) end, desc = "Test method di bawah cursor (Maven/Gradle)" },
          ["<Leader>Jm"] = { jdtls_call "test_nearest_method", desc = "Test method terdekat (Java)" },
          ["<Leader>Jk"] = { jdtls_call "test_class", desc = "Test class (Java)" },
          ["<Leader>Jo"] = { jdtls_call "organize_imports", desc = "Organize imports (Java)" },
        },
      },
    },
  },
}