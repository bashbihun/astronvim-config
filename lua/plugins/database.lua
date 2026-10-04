-- lua/plugins/database.lua
-- Database client di dalam nvim: PostgreSQL, MySQL, MongoDB, Redis (+ SQLite, dll)
-- lewat vim-dadbod + UI drawer-nya.
--
-- Setup koneksi (WAJIB diisi sendiri, jangan commit password ke git):
--   Cara 1 (disarankan): env var DBUI_URL, atau file ~/.config/nvim/dadbod-connections.json
--   Cara 2: isi langsung vim.g.dbs di bawah (contoh ada, tinggal uncomment & edit)
--
-- Keymap:
--   <leader>Du  -> toggle DBUI (drawer semua koneksi)
--   <leader>Da  -> tambah koneksi baru
--   <leader>Df  -> cari/filter buffer DBUI
--   Di dalam buffer .sql: <leader>W simpan query, <leader>E edit bind params
--   Taruh cursor di query, tekan <leader>r (mapping dadbod-ui default) buat run,
--   atau select block query lalu jalankan :DB dengan visual selection

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      -- simpan query tersimpan di sini (auto dibuat)
      vim.g.db_ui_save_location = vim.fn.stdpath "data" .. "/db_ui_queries"

      -- ======================================================
      -- CONTOH koneksi (uncomment & sesuaikan, atau pakai DBUIAddConnection)
      -- URL scheme: postgres://user:pass@host:port/dbname
      --             mysql://user:pass@host:port/dbname
      --             mongodb://user:pass@host:port/dbname
      --             redis://[:pass@]host:port[/db]
      -- ======================================================
      -- vim.g.dbs = {
      --   { name = "local-postgres", url = "postgres://postgres:postgres@localhost:5432/postgres" },
      --   { name = "local-mysql",    url = "mysql://root:root@localhost:3306/mysql" },
      --   { name = "local-mongo",    url = "mongodb://localhost:27017/test" },
      --   { name = "local-redis",    url = "redis://localhost:6379/0" },
      -- }

      -- Alternatif lebih aman: taruh koneksi di env var lalu ambil dari sana,
      -- biar credential gak nempel di dotfiles yang mungkin ke-push ke git:
      -- vim.g.dbs = {
      --   { name = "prod-postgres", url = os.getenv("PROD_DATABASE_URL") },
      -- }
    end,
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>D"] = { desc = " Database" },
          ["<Leader>Du"] = { "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
          ["<Leader>Da"] = { "<cmd>DBUIAddConnection<CR>", desc = "Add DB connection" },
          ["<Leader>Df"] = { "<cmd>DBUIFindBuffer<CR>", desc = "Find DBUI buffer" },
        },
      },
    },
  },

  -- Autocomplete SQL (nama tabel/kolom) pakai koneksi yang aktif
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "vim-dadbod-completion" })
      return opts
    end,
  },
}