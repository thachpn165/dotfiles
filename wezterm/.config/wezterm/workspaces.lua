local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
  local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

  -- Periodic auto-save every 5 minutes
  resurrect.state_manager.periodic_save({
    interval_seconds = 300,
    save_workspaces = true,
    save_windows = false,
    save_tabs = true,
  })

  -- Save when switching workspace
  wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, pane, label)
    resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
  end)

  wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, pane, label)
    resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
  end)

  -- Add workspace keybindings to existing keys
  config.keys = config.keys or {}

  -- Leader + s: Save current workspace session
  table.insert(config.keys, {
    key = "s",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      win:toast_notification("WezTerm", "Session saved!", nil, 3000)
    end),
  })

  -- Leader + r: Restore session (fuzzy finder)
  table.insert(config.keys, {
    key = "r",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)")
        id = string.match(id, "([^/]+)$")
        id = string.match(id, "(.+)%.%..+$")
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(id, "workspace")
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.state_manager.load_state(id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.state_manager.load_state(id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
  })
end

return M
