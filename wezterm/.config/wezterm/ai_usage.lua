local wezterm = require("wezterm")

local M = {}

local cache = {
  last_check = 0,
  items = {},
}

local CACHE_TTL_SECONDS = 300

local function load_usage()
  local now = os.time()
  if now - cache.last_check < CACHE_TTL_SECONDS then
    return cache.items
  end

  local script = wezterm.config_dir .. "/scripts/ai-usage.js"
  local command = string.format("%q %q", "node", script)
  local ok, stdout = wezterm.run_child_process({ "/bin/zsh", "-lc", command })
  if ok and stdout and stdout ~= "" then
    local parsed_ok, parsed = pcall(wezterm.json_parse, stdout)
    if parsed_ok and type(parsed) == "table" then
      cache.last_check = now
      cache.items = parsed
      return cache.items
    end
  end

  cache.last_check = now
  return cache.items
end

function M.get_segments(pane)
  local usage = load_usage()
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
