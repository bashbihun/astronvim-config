-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
      "javascript",
      "typescript",
      "tsx",
      "json",
      "jsonc",
      "go",
      "gomod",
      "gowork",
      "gosum",
      "c",
      "cpp",
      "cmake",
      "make",
      "bash",
      "lua",
      "yaml",
      "markdown",
      "markdown_inline",
    })
    return opts
  end,
}
