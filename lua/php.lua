-- lua/plugins/php.lua
-- PHP & Laravel.
--
-- Pembagian tugas:
--   * LSP/format/debug/blade/laravel.nvim : astrocommunity.pack.laravel (lua/community.lua)
--       -> phpactor, php-cs-fixer, php-debug-adapter, blade (treesitter+LSP+formatter),
--          laravel.nvim (picker artisan/routes/make), laravel-ide-helper.nvim, blade-nav.nvim
--       Catatan: phpactor dipasang Mason lewat composer, jadi `php` + `composer` harus ada.
--   * Test   : neotest-phpunit & neotest-pest (lihat testing.lua)
--   * File ini: pembuat project Laravel, runner artisan, test via CLI, DAP Xdebug, formatter Pint.
--
-- Prasyarat sistem (TIDAK diinstall Mason): php (8.2+), composer, ekstensi php umum
-- (mbstring, xml, curl, zip, sqlite3/mysql), dan (opsional) docker untuk Laravel Sail.
-- Debug: ekstensi Xdebug 3 (port 9003).
--
-- Keymap (<leader>P):
--   Pn  Buat project Laravel baru (composer create-project)
--   Pr  php artisan serve        Pm  artisan migrate        Pi  artisan tinker (float)
--   Pa  artisan <perintah> (input bebas, mis. make:model Post -mfc)
--   Pt  Test semua (artisan test)
--   Pf  Test file aktif          PM  Test method di bawah cursor (--filter)
--   Ph  Install & generate laravel-ide-helper (autocomplete facade/model)
--   Pp  Ganti PHPUnit -> Pest
--
-- Opsi: :let g:php_use_sail = v:true  -> semua perintah artisan lewat ./vendor/bin/sail artisan
--       (container Sail harus sudah jalan: ./vendor/bin/sail up -d)

-- composer global bin (mis. `laravel` installer) ditambahkan ke PATH kalau ada
for _, d in ipairs { "~/.config/composer/vendor/bin", "~/.composer/vendor/bin" } do
  d = vim.fn.expand(d)
  if vim.fn.isdirectory(d) == 1 and not (":" .. vim.env.PATH .. ":"):find(":" .. d .. ":", 1, true) then
    vim.env.PATH = vim.env.PATH .. ":" .. d
  end
end

local function has(f) return vim.fn.filereadable(vim.fn.getcwd() .. "/" .. f) == 1 end

local function ask(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default }, function(v)
    if v == nil then return vim.notify("Dibatalkan", vim.log.levels.WARN) end
    cb(v ~= "" and v or default)
  end)
end

local function term(cmd, count, direction)
  require("toggleterm").exec(cmd, count, nil, nil, direction or "horizontal")
end

local function artisan()
  if vim.g.php_use_sail and has "vendor/bin/sail" then return "./vendor/bin/sail artisan" end
  return "php artisan"
end

local function in_laravel()
  if has "artisan" then return true end
  vim.notify("Bukan project Laravel (file `artisan` tidak ada di " .. vim.fn.getcwd() .. ")", vim.log.levels.WARN)
end

-- ---------- test via CLI ----------
local function test_cmd(file, filter)
  local suffix = (file and (" " .. vim.fn.shellescape(file)) or "") .. (filter and (" --filter=" .. vim.fn.shellescape(filter)) or "")
  if has "artisan" then return artisan() .. " test" .. suffix end
  if has "tests/Pest.php" and has "vendor/bin/pest" then return "vendor/bin/pest" .. suffix end
  if has "vendor/bin/phpunit" then return "vendor/bin/phpunit" .. suffix end
  vim.notify("Tidak ketemu artisan / vendor/bin/pest / vendor/bin/phpunit (jalankan `composer install`)", vim.log.levels.WARN)
end

local function run_test(kind)
  local cmd
  if kind == "all" then
    cmd = test_cmd()
  else
    local file = vim.fn.expand "%:."
    if not file:match "%.php$" then return vim.notify("Buka file test .php dulu", vim.log.levels.WARN) end
    cmd = test_cmd(file, kind == "method" and vim.fn.expand "<cword>" or nil)
  end
  if cmd then term(cmd) end
end

-- ---------- project baru ----------
local function laravel_new()
  if vim.fn.executable "php" ~= 1 or vim.fn.executable "composer" ~= 1 then
    return vim.notify("Butuh `php` dan `composer` di PATH", vim.log.levels.ERROR)
  end
  ask("Nama project: ", "my-app", function(name)
    ask("Versi Laravel (kosong = terbaru, mis. ^11.0): ", "", function(version)
      ask("Simpan di folder: ", vim.fn.getcwd(), function(parent)
        parent = vim.fn.expand(parent)
        local dest = parent .. "/" .. name
        if vim.fn.isdirectory(dest) == 1 then
          return vim.notify(dest .. " sudah ada", vim.log.levels.ERROR)
        end
        local args = { "composer", "create-project", "--prefer-dist", "--no-interaction", "laravel/laravel", name }
        if version ~= "" then table.insert(args, version) end
        vim.notify("composer create-project laravel/laravel ... (tunggu, bisa beberapa menit)")
        vim.system(args, { cwd = parent, text = true }, function(res)
          vim.schedule(function()
            if res.code ~= 0 then
              local out = (res.stderr or "") .. (res.stdout or "")
              return vim.notify("composer gagal:\n" .. out:sub(-1500), vim.log.levels.ERROR)
            end
            vim.system({ "git", "init", "-q" }, { cwd = dest }):wait()
            vim.cmd("cd " .. vim.fn.fnameescape(dest))
            if vim.fn.filereadable(dest .. "/routes/web.php") == 1 then vim.cmd("edit routes/web.php") end
            pcall(vim.cmd, "Neotree show")
            vim.notify("Project Laravel siap: " .. dest .. "\n<leader>Pr = serve, <leader>Pt = test")
          end)
        end)
      end)
    end)
  end)
end

local function install_ide_helper()
  if not in_laravel() then return end
  if vim.fn.confirm("Tambah barryvdh/laravel-ide-helper ke composer.json (dev) lalu generate stub?", "&Ya\n&Batal", 2) ~= 1 then
    return
  end
  local a = artisan()
  term(
    "composer require --dev barryvdh/laravel-ide-helper && "
      .. a .. " ide-helper:generate && " .. a .. " ide-helper:models --nowrite && " .. a .. " ide-helper:meta"
  )
end

local function install_pest()
  if not in_laravel() then return end
  if vim.fn.confirm("Ganti PHPUnit dengan Pest di project ini? (mengubah composer.json & tests/)", "&Ya\n&Batal", 2) ~= 1 then
    return
  end
  term(
    "composer remove phpunit/phpunit --dev --no-interaction && "
      .. "composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies --no-interaction && "
      .. artisan() .. " pest:install --no-interaction"
  )
end

local function artisan_prompt()
  if not in_laravel() then return end
  ask("artisan ", "list", function(c) term(artisan() .. " " .. c) end)
end

local function simple(sub, count, direction)
  return function()
    if in_laravel() then term(artisan() .. " " .. sub, count, direction) end
  end
end

return {
  -- parser treesitter (blade ditangani pack blade)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "php", "phpdoc", "html", "css",
      })
      return opts
    end,
  },

  -- formatter: Laravel Pint (vendor/bin/pint) dulu, kalau tidak ada pakai php-cs-fixer
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.php = { "pint", "php_cs_fixer", stop_after_first = true }
      return opts
    end,
  },

  {
    "AstroNvim/astrocore",
    opts = {
      commands = {
        LaravelNew = { laravel_new, desc = "Buat project Laravel baru (composer)" },
      },
      -- Debug PHP (Xdebug 3, port 9003) memakai php-debug-adapter dari Mason.
      -- Hanya dipasang kalau pack/config lain belum mendefinisikannya.
      autocmds = {
        php_dap = {
          {
            event = "FileType",
            pattern = { "php", "blade" },
            desc = "Setup nvim-dap untuk PHP (Xdebug)",
            callback = function()
              local ok, dap = pcall(require, "dap")
              if not ok then return end
              if not dap.adapters.php then
                local mason_bin = vim.fn.stdpath "data" .. "/mason/bin/php-debug-adapter"
                dap.adapters.php = { type = "executable", command = vim.fn.executable(mason_bin) == 1 and mason_bin or "php-debug-adapter" }
              end
              if not dap.configurations.php then
                dap.configurations.php = {
                  { type = "php", request = "launch", name = "Listen for Xdebug (lokal)", port = 9003 },
                  {
                    type = "php", request = "launch", name = "Listen for Xdebug (Laravel Sail)", port = 9003,
                    pathMappings = { ["/var/www/html"] = "${workspaceFolder}" },
                  },
                }
              end
            end,
          },
        },
      },
      mappings = {
        n = {
          ["<Leader>P"] = { desc = " PHP / Laravel" },
          ["<Leader>Pn"] = { laravel_new, desc = "New Laravel project" },
          ["<Leader>Pr"] = { simple("serve", 8), desc = "artisan serve" },
          ["<Leader>Pm"] = { simple "migrate", desc = "artisan migrate" },
          ["<Leader>Pi"] = { simple("tinker", 7, "float"), desc = "artisan tinker" },
          ["<Leader>Pa"] = { artisan_prompt, desc = "artisan <perintah>" },
          ["<Leader>Pt"] = { function() run_test "all" end, desc = "Test semua (artisan test)" },
          ["<Leader>Pf"] = { function() run_test "file" end, desc = "Test file aktif" },
          ["<Leader>PM"] = { function() run_test "method" end, desc = "Test method di bawah cursor" },
          ["<Leader>Ph"] = { install_ide_helper, desc = "Install laravel-ide-helper + generate" },
          ["<Leader>Pp"] = { install_pest, desc = "Ganti PHPUnit -> Pest" },
        },
      },
    },
  },
}