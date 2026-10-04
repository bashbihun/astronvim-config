-- lua/plugins/lsp-noise-fix.lua
-- vtsls (LSP untuk TS/JS/Vue) punya bug lama: kadang gagal jawab request
-- textDocument/documentHighlight pas ganti buffer/tab cepat. Ini harmless
-- (fitur LSP lain tetap jalan normal), tapi notifikasinya spam & mengganggu.
-- Ref: https://github.com/LazyVim/LazyVim/issues/3465
--      https://github.com/vuejs/language-tools/discussions/5456
--
-- File ini TIDAK menambah plugin apapun (return-nya kosong), jadi aman
-- digabung dengan file plugin lain tanpa bentrok opts/config.

local orig_notify = vim.notify
vim.notify = function(msg, level, notify_opts)
  if type(msg) == "string" and msg:match("vtsls") and msg:match("documentHighlight") then
    return -- diamkan, ini noise dari bug vtsls, bukan error beneran
  end
  return orig_notify(msg, level, notify_opts)
end

return {}
