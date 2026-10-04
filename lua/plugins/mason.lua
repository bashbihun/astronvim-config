-- lua/plugins/mason.lua
return {
  "williamboman/mason.nvim",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      -- LSP
      "typescript-language-server", -- dipakai untuk Node & Bun (JS/TS)
      "gopls",
      "clangd",
      "vue-language-server", -- vue (volar)
      "svelte-language-server", -- svelte
      "sqlls", -- sql (postgres/mysql/dll, via file .sqllsrc.json)

      -- Formatter
      "prettier", -- js/ts
      "gofumpt", -- go
      "goimports", -- go
      "clang-format", -- c/cpp
      "sql-formatter", -- sql
      "stylua", -- lua config kamu sendiri

      -- Linter
      "eslint_d", -- js/ts
      "golangci-lint", -- go

      -- DAP (debugger)
      "js-debug-adapter", -- node & bun (protokol debug sama, ini adapternya)
      "delve", -- go
      "codelldb", -- c/cpp
    })
    return opts
  end,
}