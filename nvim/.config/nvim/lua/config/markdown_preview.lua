local M = {}

local state = {
  win = nil,
  buf = nil,
}

local function is_markdown(bufnr)
  local ft = vim.bo[bufnr].filetype
  return ft == "markdown" or ft == "md" or ft == "rmd" or ft == "quarto"
end

local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function open_for_file(path)
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].filetype = "markdown"

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  -- Close with q / Esc
  vim.keymap.set("n", "q", close, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = state.buf, silent = true })

  -- Render with glow in a terminal buffer inside the floating window
  vim.fn.termopen({ "glow", "-p", path }, { cwd = vim.fn.fnamemodify(path, ":h") })
  vim.cmd("startinsert")
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    close()
    return
  end

  if vim.fn.executable("glow") == 0 then
    vim.notify("glow is not installed. Install it to enable markdown preview.", vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not is_markdown(bufnr) then
    vim.notify("Markdown preview works best in markdown buffers.", vim.log.levels.INFO)
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.notify("Buffer has no file path. Save it first.", vim.log.levels.WARN)
    return
  end

  open_for_file(path)
end

-- Keep a compatibility command for old mappings / muscle memory.
vim.api.nvim_create_user_command("MarkdownPreviewToggle", function()
  M.toggle()
end, {})

return M

