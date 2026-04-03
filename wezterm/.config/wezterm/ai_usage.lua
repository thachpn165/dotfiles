local wezterm = require("wezterm")

local M = {}

local cache = {
  cwd = "",
  last_check = 0,
  items = {},
}

local CACHE_TTL_SECONDS = 60

local function get_pane_cwd(pane)
  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return ""
  end

  return cwd_uri.file_path or ""
end

local function load_usage(cwd)
  local now = os.time()
  if cache.cwd == cwd and now - cache.last_check < CACHE_TTL_SECONDS then
    return cache.items
  end

  local script = wezterm.config_dir .. "/scripts/ai-usage.js"
  local command = string.format("%q %q %q", "node", script, cwd)
  local ok, stdout = wezterm.run_child_process({ "/bin/zsh", "-lc", command })
  if ok and stdout and stdout ~= "" then
    local parsed_ok, parsed = pcall(wezterm.json_parse, stdout)
    if parsed_ok and type(parsed) == "table" then
      cache.cwd = cwd
      cache.last_check = now
      cache.items = parsed
      return cache.items
    end
  end

  cache.cwd = cwd
  cache.last_check = now
  return cache.items
end

function M.get_segments(pane)
  local usage = load_usage(get_pane_cwd(pane))
  local segments = {}

  for _, key in ipairs({ "codex", "claude" }) do
    local item = usage[key]
    if item and item.available and item.value and item.value ~= "" then
      table.insert(segments, {
        key = key,
        text = item.label .. " " .. item.value,
        mode = item.mode or "default",
      })
    end
  end

  return segments
end

return M
