-- lua/plugins/dapui.lua
-- Tambahan UI untuk debugger (dipakai bareng adapter yang sudah didaftarkan
-- di lua/plugins/dap.lua: js-debug-adapter, delve, codelldb).
--
-- Keymap:
--   <leader>db  -> toggle breakpoint
--   <leader>dB  -> breakpoint dengan kondisi (conditional)
--   <leader>dc  -> continue / mulai debug
--   <leader>di  -> step into
--   <leader>do  -> step over
--   <leader>dO  -> step out
--   <leader>dr  -> buka REPL
--   <leader>du  -> toggle dap-ui (variables, breakpoints, watch, dst)
--   <leader>dt  -> terminate session

return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = {},
    config = function(_, opts)
      local dap, dapui = require "dap", require "dapui"
      dapui.setup(opts)
      -- auto buka/tutup dapui pas session mulai/selesai
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = { commented = true },
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>d"] = { desc = " Debugger" },
          ["<Leader>db"] = {
            function() require("dap").toggle_breakpoint() end,
            desc = "Toggle breakpoint",
          },
          ["<Leader>dB"] = {
            function()
              vim.ui.input({ prompt = "Kondisi breakpoint: " }, function(cond)
                if cond then require("dap").set_breakpoint(cond) end
              end)
            end,
            desc = "Conditional breakpoint",
          },
          ["<Leader>dc"] = {
            function() require("dap").continue() end,
            desc = "Continue / start debug",
          },
          ["<Leader>di"] = {
            function() require("dap").step_into() end,
            desc = "Step into",
          },
          ["<Leader>do"] = {
            function() require("dap").step_over() end,
            desc = "Step over",
          },
          ["<Leader>dO"] = {
            function() require("dap").step_out() end,
            desc = "Step out",
          },
          ["<Leader>dr"] = {
            function() require("dap").repl.toggle() end,
            desc = "Toggle REPL",
          },
          ["<Leader>du"] = {
            function() require("dapui").toggle() end,
            desc = "Toggle debugger UI",
          },
          ["<Leader>dt"] = {
            function() require("dap").terminate() end,
            desc = "Terminate session",
          },
        },
      },
    },
  },
}
