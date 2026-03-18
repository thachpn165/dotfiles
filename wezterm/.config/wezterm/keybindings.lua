local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

function M.apply(config)
  -- Leader key: Ctrl+A with 2s timeout
  config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

  config.keys = {
    -- Pane splitting
    { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

    -- Pane navigation (vim-style)
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- Pane resizing
    { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

    -- Tab management
    { key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },

    -- Tab by number (Leader + 1-9)
    { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
    { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
    { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
    { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
    { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
    { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
    { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
    { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
    { key = "9", mods = "LEADER", action = act.ActivateTab(8) },

    -- Workspace switcher
    { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

    -- Create new workspace (Leader + W)
    {
      key = "W",
      mods = "LEADER|SHIFT",
      action = act.PromptInputLine({
        description = wezterm.format({
          { Foreground = { Color = "#cba6f7" } },
          { Text = "Enter workspace name: " },
        }),
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
          end
        end),
      }),
    },

    -- Zoom & Fullscreen
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    { key = "f", mods = "LEADER", action = act.ToggleFullScreen },

    -- Command palette
    { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },

    -- Shift+Enter: send unique escape sequence (zsh binds this to insert newline)
    { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") },

    -- Send Ctrl+A to terminal (press Ctrl+A twice)
    { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
  }
end

return M
