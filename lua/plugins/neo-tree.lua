-- lua/plugins/neo-tree.lua
-- Biar file explorer (Neo-tree) nampilin SEMUA file, termasuk:
--   - dotfiles (.gitignore, .npmrc, .vscode, .env, dll)
--   - file/folder yang kena .gitignore (node_modules, dist, build, dll)
--
-- Toggle cepat kalau sewaktu-waktu mau sembunyikan lagi:
--   <leader>e lalu tekan `H` di dalam Neo-tree -> toggle hidden files
--   `.` (dot) di dalam Neo-tree juga toggle dotfiles di beberapa versi

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- item yang di-filter tetap ditampilkan (redup), bukan disembunyikan total
        hide_dotfiles = false, -- jangan sembunyikan .gitignore, .npmrc, .env, dll
        hide_gitignored = false, -- jangan sembunyikan file/folder yang ada di .gitignore
        hide_hidden = false, -- windows: jangan sembunyikan hidden file
        hide_by_name = {
          -- kalau ada yang MASIH mau disembunyikan spesifik, taruh nama di sini
          -- ".git",
        },
        never_show = {
          -- ini yang beneran gak akan pernah muncul walau show all, kosongkan kalau mau full
          ".DS_Store",
          "thumbs.db",
        },
      },
    },
  },
}
