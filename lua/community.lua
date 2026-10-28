-- lua/community.lua
-- PENTING: file ini HARUS berada langsung di ~/.config/nvim/lua/community.lua
-- (bukan di dalam folder lua/plugins/). Ini dimuat oleh AstroNvim sebelum
-- folder lua/plugins/ diproses.
--
-- Paket ini otomatis mengurus Treesitter parser + LSP + formatter dasar
-- untuk masing-masing bahasa. Kita tinggal menambah/menimpa hal spesifik
-- (mis. neotest, dap tambahan) di file-file lain dalam lua/plugins/.
return {
  "AstroNvim/astrocommunity",

  -- JS / TS (Node & Bun jalan di parser/LSP yang sama: tsserver)
  { import = "astrocommunity.pack.typescript" },

  -- Go
  { import = "astrocommunity.pack.go" },

  -- C / C++
  { import = "astrocommunity.pack.cpp" },

  -- Vue.js (otomatis include pack typescript juga)
  { import = "astrocommunity.pack.vue" },
 
  -- Svelte (otomatis include pack typescript juga)
  { import = "astrocommunity.pack.svelte" },

  -- PHP + Laravel: phpactor, php-cs-fixer, php-debug-adapter, blade, laravel.nvim, ide-helper, blade-nav
  -- (otomatis mengimpor pack php, html-css, dan blade). Butuh `php` + `composer` di sistem.
  { import = "astrocommunity.pack.laravel" },

  -- Java: jdtls + nvim-jdtls + java-debug-adapter + java-test (+ lemminx buat pom.xml)
  -- Kotlin & Spring Boot ada di lua/plugins/jvm.lua
  { import = "astrocommunity.pack.java" },
}
