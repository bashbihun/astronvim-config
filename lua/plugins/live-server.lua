-- lua/plugins/live-server.lua
-- Live Server (kayak ekstensi "Live Server" di VSCode) — jalanin static
-- server buat HTML/CSS/JS, browser auto-reload tiap kali file di-save.
-- Pakai npm package `live-server` asli di belakang layar (bukan reimplementasi),
-- jadi recursive file watching di folder css/js/dll tetap kerja normal.
--
-- Keymap:
--   <leader>Ws  -> start live server (folder project saat ini)
--   <leader>Wx  -> stop live server
--   <leader>Wt  -> toggle (start kalau mati, stop kalau nyala)

return {
  {
    "ngtuonghy/live-server-nvim",
    event = "VeryLazy",
    build = ":LiveServerInstall", -- sekali jalan, download binary live-server via npm
    cmd = { "LiveServerStart", "LiveServerStop", "LiveServerToggle" },
    config = function()
      require("live-server-nvim").setup {
        custom = { "--port=8080" }, -- tambah flag lain kalau perlu, mis. "--no-css-inject"
        serverPath = vim.fn.stdpath "data" .. "/live-server/",
        open = "folder", -- "folder" = serve root project, "cwd" = serve directory nvim dijalankan
      }
    end,
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>W"] = { desc = " Live Server" },
          ["<Leader>Ws"] = { "<cmd>LiveServerStart<CR>", desc = "Start live server" },
          ["<Leader>Wx"] = { "<cmd>LiveServerStop<CR>", desc = "Stop live server" },
          ["<Leader>Wt"] = { "<cmd>LiveServerToggle<CR>", desc = "Toggle live server" },
        },
      },
    },
  },
}
