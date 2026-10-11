-- lua/plugins/testing.lua
-- Neotest = satu framework untuk semua bahasa. Setiap bahasa punya "adapter".
-- Cara jalanin test (sama untuk semua bahasa, lihat keymap di bawah):
--   <leader>tt  -> run nearest (per method/function, taruh cursor di dalam test-nya)
--   <leader>tf  -> run current file (per file)
--   <leader>tw  -> run whole project / workspace (suite)
--   <leader>td  -> debug nearest test (pakai DAP)
--   <leader>ts  -> toggle summary panel (lihat semua test + status)
--   <leader>to  -> lihat output test yang gagal
--
-- Java/Kotlin/Spring (pembagian adapter, supaya tidak dobel):
--   * Java   (Maven & Gradle, JUnit 5/6, Spring)  -> neotest-java  (perlu jdtls aktif + `<leader>tJ` sekali)
--   * Kotlin (Gradle)                             -> neotest-gradle (dibatasi hanya file .kt)
--   * Kotlin (Maven) / project polos src/lib/bin -> belum ada adapter neotest; pakai <leader>Jf / JM / Jt (jvm.lua)

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- JS/TS runtime: Node & Bun
      "marilari88/neotest-vitest", -- kalau project pakai vitest
      "nvim-neotest/neotest-jest", -- kalau project pakai jest
      "jutonz/neotest-bun", -- kalau project pakai `bun test`

      -- Go
      "fredrikaverpil/neotest-golang", -- lebih stabil dibanding neotest-go

      -- C/C++ (GoogleTest, Catch2, doctest lewat CTest)
      "orjangj/neotest-ctest",

      -- Java: Maven & Gradle, JUnit 5/6, Spring (application.yml/properties otomatis dimuat),
      -- butuh nvim-jdtls (dari astrocommunity.pack.java) + treesitter parser java
      "rcasia/neotest-java",
      "mfussenegger/nvim-jdtls",

      -- Kotlin (project Gradle, JUnit)
      "weilbith/neotest-gradle",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}

      -- JS/TS: neotest akan mencoba tiap adapter dan pakai yang cocok
      -- (jest kalau ada jest.config.*, vitest kalau ada vitest.config.*,
      --  bun kalau ada package.json tapi tidak keduanya / kamu jalankan `bun test`)
      table.insert(
        opts.adapters,
        require("neotest-jest")({
          jestCommand = "npx jest",
          cwd = function(path) return vim.fn.getcwd() end,
        })
      )
      table.insert(opts.adapters, require("neotest-vitest"))
      table.insert(opts.adapters, require("neotest-bun"))

      -- Go (neotest-golang v2 API)
      table.insert(
        opts.adapters,
        require("neotest-golang")({
          go_test_args = { "-v", "-race", "-count=1" },
          dap_mode = "dap-go", -- pakai leoluz/nvim-dap-go (default)
        })
      )

      -- C/C++ (butuh project dikonfigurasi CMake + `enable_testing()` +
      -- gtest_discover_tests()/catch_discover_tests(), lalu sudah pernah `ctest` sekali
      -- supaya CTestTestfile.cmake ada di folder build)
      table.insert(
        opts.adapters,
        require("neotest-ctest").setup({
          frameworks = { "gtest", "catch2", "doctest" },
        })
      )

      -- Java/Kotlin Gradle (pcall: kalau gagal load, adapter lain tetap jalan)
      -- Java (Maven & Gradle, Spring). pcall: kalau gagal, adapter lain tetap jalan
      local ok_java, java = pcall(require, "neotest-java")
      if ok_java then
        local ok_adapter, adapter = pcall(java, {
          incremental_build = true, -- compile ulang hanya file yang berubah (via jdtls)
          -- jvm_args = { "-Xmx512m" },
        })
        if ok_adapter then
          table.insert(opts.adapters, adapter)
        else
          vim.notify("neotest-java gagal di-setup: " .. tostring(adapter), vim.log.levels.WARN)
        end
      end

      -- Kotlin Gradle. Dibatasi hanya file .kt, karena file .java sudah ditangani neotest-java
      -- (kalau tidak dibatasi, test Java di project Gradle muncul dobel di summary)
      local ok_gradle, gradle = pcall(require, "neotest-gradle")
      if ok_gradle then
        local orig_is_test_file = gradle.is_test_file
        if type(orig_is_test_file) == "function" then
          gradle.is_test_file = function(file_path)
            return file_path ~= nil and file_path:match "%.kt$" ~= nil and orig_is_test_file(file_path)
          end
        end
        table.insert(opts.adapters, gradle)
      end

      opts.status = { virtual_text = true }
      opts.output = { open_on_run = true }
      opts.quickfix = { open = false }

      return opts
    end,
  },

  -- keymap testing (global, semua filetype)
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>t"] = { desc = " Test" },
          ["<Leader>tt"] = {
            function() require("neotest").run.run() end,
            desc = "Run nearest test (method/function)",
          },
          ["<Leader>tf"] = {
            function() require("neotest").run.run(vim.fn.expand "%") end,
            desc = "Run current file",
          },
          ["<Leader>tw"] = {
            function() require("neotest").run.run(vim.uv.cwd()) end,
            desc = "Run whole project (suite)",
          },
          ["<Leader>td"] = {
            function() require("neotest").run.run { strategy = "dap" } end,
            desc = "Debug nearest test",
          },
          ["<Leader>tl"] = {
            function() require("neotest").run.run_last() end,
            desc = "Run last test",
          },
          ["<Leader>ts"] = {
            function() require("neotest").summary.toggle() end,
            desc = "Toggle test summary panel",
          },
          ["<Leader>to"] = {
            function() require("neotest").output.open { enter = true, auto_close = true } end,
            desc = "Show test output",
          },
          ["<Leader>tJ"] = {
            "<cmd>NeotestJava setup<CR>",
            desc = "Setup/update JUnit jar (neotest-java)",
          },
          ["<Leader>tS"] = {
            function() require("neotest").run.stop() end,
            desc = "Stop running test",
          },
        },
      },
    },
  },
}