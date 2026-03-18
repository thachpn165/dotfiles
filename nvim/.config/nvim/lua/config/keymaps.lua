-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- telescope
vim.keymap.set("n", "<leader>fs", ":Telescope find_files<cr>")
vim.keymap.set("n", "<leader>fz", ":Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fo", ":Telescope oldfiles<cr>")
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fh", ":Telescope help_tags<cr>")


-- icon picker
vim.keymap.set("n", "<leader>ic", ":IconPickerNormal<cr>", { noremap = true, silent = true })

-- twilight
vim.keymap.set("n", "<leader>il", ":Twilight<cr>")

-- zen mode
vim.keymap.set("n", "<leader>zm", ":ZenMode<cr>")

-- format code using LSP
-- vim.keymap.set("n", "<leader>pp", vim.lsp.buf.format)

-- markdown preview
vim.keymap.set("n", "<leader>mp", function()
  require("config.markdown_preview").toggle()
end, { desc = "Markdown Preview (toggle)" })

-- comment (use Comment.nvim API; LazyVim includes it by default)
vim.keymap.set("n", "<leader>/", function()
  local ok, api = pcall(require, "Comment.api")
  if ok then
    api.toggle.linewise.current()
  end
end, { desc = "Toggle Comment" })
vim.keymap.set("v", "<leader>/", function()
  local ok, api = pcall(require, "Comment.api")
  if not ok then
    return
  end
  -- Toggle current visual selection, then return to normal mode
  local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  api.toggle.linewise(vim.fn.visualmode())
end, { desc = "Toggle Comment (Visual)" })

------------------
-- goto-preview --
------------------
--
-- note: lsp config (from lsp.lua)
-- nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
-- nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
-- nmap('gt', vim.lsp.buf.type_definition, 'Type [D]efinition')
-- nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
--
vim.keymap.set("n", "<leader>gd", ":lua require('goto-preview').goto_preview_definition()<CR>")
vim.keymap.set("n", "<leader>gt", ":lua require('goto-preview').goto_preview_type_definition()<CR>")
vim.keymap.set("n", "<leader>gi", ":lua require('goto-preview').goto_preview_implementation()<CR>")
vim.keymap.set("n", "<leader>gp", ":lua require('goto-preview').close_all_win()<CR>")
