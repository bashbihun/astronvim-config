-- lua/plugins/dap.lua
return {
  -- Go debugging (dipakai juga oleh neotest-golang via dap_go_enabled)
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    opts = {},
  },

  -- Node & Bun debugging (vscode-js-debug, terinstall via mason: js-debug-adapter)
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    opts = {
      -- path ke js-debug-adapter yang diinstall mason
      debugger_path = vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter",
      adapters = { "pwa-node", "pwa-chrome", "node-terminal" },
    },
    config = function(_, opts)
      require("dap-vscode-js").setup(opts)
      local dap = require "dap"
      for _, lang in ipairs { "javascript", "typescript", "javascriptreact", "typescriptreact" } do
        dap.configurations[lang] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file (node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file (bun)",
            runtimeExecutable = "bun",
            runtimeArgs = { "run" },
            program = "${file}",
            cwd = "${workspaceFolder}",
            attachSimplePort = 9229,
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  },

  -- C/C++ debugging pakai codelldb (terinstall via mason)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
      local dap = require "dap"
      local mason_path = vim.fn.stdpath "data" .. "/mason/packages/codelldb"
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason_path .. "/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }
      for _, lang in ipairs { "c", "cpp" } do
        dap.configurations[lang] = {
          {
            name = "Launch executable",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path ke executable: ", vim.fn.getcwd() .. "/build/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
        }
      end
    end,
  },
}
