local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
  config.keys = config.keys or {}

  -- Ctrl+Shift+A: AI Assistant (opens in bottom pane with IME support)
  table.insert(config.keys, {
    key = "phys:A",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      -- Save last 50 lines of terminal output to a temp file for context
      local dims = pane:get_dimensions()
      local end_y = dims.scrollback_top + dims.scrollback_rows + dims.viewport_rows - 1
      local start_y = math.max(dims.scrollback_top, end_y - 49)
      local cols = dims.cols or 200
      local context = pane:get_text_from_region(0, start_y, cols, end_y) or ""

      local tmp = os.tmpname()
      local f = io.open(tmp, "w")
      if f then
        f:write(context)
        f:close()
      end

      -- Get path to ai-ask.sh relative to config
      local config_dir = wezterm.config_dir
      local script = config_dir .. "/scripts/ai-ask.sh"

      -- Pass parent pane ID so script can send commands back
      local parent_pane_id = tostring(pane:pane_id())

      -- Get current working directory of the pane
      local cwd = ""
      local cwd_uri = pane:get_current_working_dir()
      if cwd_uri then
        cwd = cwd_uri.file_path or ""
      end

      -- Open bottom pane running the AI script
      pane:split({
        direction = "Bottom",
        size = 0.4,
        args = { "bash", script, tmp, parent_pane_id, cwd },
      })
    end),
  })
end

return M
