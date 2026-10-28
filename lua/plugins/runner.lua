-- -- lua/plugins/runner.lua
-- -- Runner cepat buat jalanin FILE AKTIF langsung (bukan lewat neotest),
-- -- misalnya buat nyoba script/main function tanpa nulis test dulu.
-- -- Jalan di floating terminal (toggleterm).
-- --
-- -- Keymap:
-- --   <leader>rr  -> run file aktif (auto detect bahasa: bun/node/go run/gcc+jalankan/g++)
-- --   <leader>rc  -> run file aktif, command custom (input manual)


-- local function get_run_cmd()
--   local ft = vim.bo.filetype
--   local file = vim.fn.expand "%:p"
--   local file_noext = vim.fn.expand "%:p:r"
--   local cwd = vim.fn.getcwd()

--   if ft == "javascript" then
--     local has_bun = vim.fn.filereadable(cwd .. "/bun.lockb") == 1
--       or vim.fn.filereadable(cwd .. "/bunfig.toml") == 1
--     return (has_bun and "bun run " or "node ") .. vim.fn.shellescape(file)
--   elseif ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
--     -- TS butuh runtime yang bisa transpile langsung: bun
--     return "bun run " .. vim.fn.shellescape(file)
--   elseif ft == "go" then
--     return "go run " .. vim.fn.shellescape(file)
--   elseif ft == "c" then
--     return "gcc " .. vim.fn.shellescape(file) .. " -o " .. vim.fn.shellescape(file_noext)
--       .. " && " .. vim.fn.shellescape(file_noext)
--   elseif ft == "cpp" then
--     return "g++ -std=c++20 " .. vim.fn.shellescape(file) .. " -o " .. vim.fn.shellescape(file_noext)
--       .. " && " .. vim.fn.shellescape(file_noext)
--   else
--     vim.notify("Belum ada runner untuk filetype: " .. ft, vim.log.levels.WARN)
--     return nil
--   end
-- end

-- return {
--   {
--     "akinsho/toggleterm.nvim",
--     opts = {
--       size = function(term)
--         if term.direction == "horizontal" then
--           return 15
--         elseif term.direction == "vertical" then
--           return math.floor(vim.o.columns * 0.4)
--         end
--       end,
--       open_mapping = [[<c-\>]], -- Ctrl+\ toggle terminal terakhir yang dipakai
--       direction = "float",
--       persist_size = true,
--     },
--   },

--   {
--     "AstroNvim/astrocore",
--     opts = {
--       mappings = {
--         n = {
--           ["<Leader>r"] = { desc = " Run" },
--           ["<Leader>rr"] = {
--             function()
--               local cmd = get_run_cmd()
--               if cmd then require("toggleterm").exec(cmd, nil, nil, nil, "float") end
--             end,
--             desc = "Run current file",
--           },
--           ["<Leader>rc"] = {
--             function()
--               vim.ui.input({ prompt = "Command: ", default = "" }, function(input)
--                 if input and input ~= "" then
--                   require("toggleterm").exec(input, nil, nil, nil, "float")
--                 end
--               end)
--             end,
--             desc = "Run current file (custom command)",
--           },

--           -- Terminal toggle: horizontal / vertical / float
--           ["<Leader>th"] = {
--             function() require("toggleterm").toggle(0, nil, nil, "horizontal") end,
--             desc = "Terminal horizontal",
--           },
--           ["<Leader>tv"] = {
--             function() require("toggleterm").toggle(0, nil, nil, "vertical") end,
--             desc = "Terminal vertical",
--           },
--           ["<Leader>tF"] = {
--             function() require("toggleterm").toggle(0, nil, nil, "float") end,
--             desc = "Terminal float",
--           },
--         },
--         t = {
--           -- Keluar dari mode terminal langsung ke normal mode dengan Esc
--           ["<Esc>"] = { [[<C-\><C-n>]], desc = "Exit terminal mode" },
--           -- pindah antar window dari dalam terminal
--           ["<C-h>"] = { [[<Cmd>wincmd h<CR>]], desc = "Window left" },
--           ["<C-j>"] = { [[<Cmd>wincmd j<CR>]], desc = "Window down" },
--           ["<C-k>"] = { [[<Cmd>wincmd k<CR>]], desc = "Window up" },
--           ["<C-l>"] = { [[<Cmd>wincmd l<CR>]], desc = "Window right" },
--         },
--       },
--     },
--   },
-- }

-- disini yang baru
-- lua/plugins/runner.lua
-- Runner cepat buat jalanin FILE AKTIF langsung (bukan lewat neotest),
-- misalnya buat nyoba script/main function tanpa nulis test dulu.
-- Jalan di floating terminal (toggleterm).
--
-- Keymap:
--   <leader>rr  -> run file aktif (auto detect bahasa: bun/node/go run/gcc+jalankan/g++)
--                  Java/Kotlin/Spring -> diteruskan ke :JvmRun (lihat jvm.lua): Maven/Gradle/
--                  project polos src/lib/bin (output .class di bin/) / satu file .java/.kt
--   <leader>rc  -> run file aktif, command custom (input manual)

local function get_run_cmd()
  local ft = vim.bo.filetype
  local file = vim.fn.expand "%:p"
  local file_noext = vim.fn.expand "%:p:r"
  local cwd = vim.fn.getcwd()

  if ft == "javascript" then
    local has_bun = vim.fn.filereadable(cwd .. "/bun.lockb") == 1
      or vim.fn.filereadable(cwd .. "/bunfig.toml") == 1
    return (has_bun and "bun run " or "node ") .. vim.fn.shellescape(file)
  elseif ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
    -- TS butuh runtime yang bisa transpile langsung: bun
    return "bun run " .. vim.fn.shellescape(file)
  elseif ft == "php" then
    return "php " .. vim.fn.shellescape(file)
  elseif ft == "go" then
    return "go run " .. vim.fn.shellescape(file)
  elseif ft == "c" then
    return "gcc " .. vim.fn.shellescape(file) .. " -o " .. vim.fn.shellescape(file_noext)
      .. " && " .. vim.fn.shellescape(file_noext)
  elseif ft == "cpp" then
    return "g++ -std=c++20 " .. vim.fn.shellescape(file) .. " -o " .. vim.fn.shellescape(file_noext)
      .. " && " .. vim.fn.shellescape(file_noext)
  else
    vim.notify("Belum ada runner untuk filetype: " .. ft, vim.log.levels.WARN)
    return nil
  end
end

return {
  {
    "akinsho/toggleterm.nvim",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      open_mapping = [[<c-\>]], -- Ctrl+\ toggle terminal terakhir yang dipakai
      direction = "float",
      persist_size = true,
    },
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>r"] = { desc = " Run" },
          ["<Leader>rr"] = {
            function()
              local ft = vim.bo.filetype
              if ft == "java" or ft == "kotlin" then return vim.cmd "JvmRun" end
              local cmd = get_run_cmd()
              if cmd then require("toggleterm").exec(cmd, nil, nil, nil, "float") end
            end,
            desc = "Run current file",
          },
          ["<Leader>rc"] = {
            function()
              vim.ui.input({ prompt = "Command: ", default = "" }, function(input)
                if input and input ~= "" then
                  require("toggleterm").exec(input, nil, nil, nil, "float")
                end
              end)
            end,
            desc = "Run current file (custom command)",
          },

          -- Terminal toggle: horizontal / vertical / float
          ["<Leader>th"] = {
            function() require("toggleterm").toggle(0, nil, nil, "horizontal") end,
            desc = "Terminal horizontal",
          },
          ["<Leader>tv"] = {
            function() require("toggleterm").toggle(0, nil, nil, "vertical") end,
            desc = "Terminal vertical",
          },
          ["<Leader>tF"] = {
            function() require("toggleterm").toggle(0, nil, nil, "float") end,
            desc = "Terminal float",
          },
        },
        t = {
          -- Keluar dari mode terminal langsung ke normal mode dengan Esc
          ["<Esc>"] = { [[<C-\><C-n>]], desc = "Exit terminal mode" },
          -- pindah antar window dari dalam terminal
          ["<C-h>"] = { [[<Cmd>wincmd h<CR>]], desc = "Window left" },
          ["<C-j>"] = { [[<Cmd>wincmd j<CR>]], desc = "Window down" },
          ["<C-k>"] = { [[<Cmd>wincmd k<CR>]], desc = "Window up" },
          ["<C-l>"] = { [[<Cmd>wincmd l<CR>]], desc = "Window right" },
        },
      },
    },
  },
}
