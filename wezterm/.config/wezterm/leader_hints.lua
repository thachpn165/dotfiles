local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Per-window debounce for leader toast
local leader_state = {}

local function leader_toast(window, pane)
  local msg =
    "Leader keys: split(|,-) move(hjkl) resize(HJKL) tab(n,[,]) ws(w,W,d) sess(s,r) ssh(g) notes(N) zoom(z) full(f) close(x) help(?)"
  window:toast_notification("WezTerm", msg, nil, 4000)
end

function M.setup()
  wezterm.on("update-status", function(window, pane)
    local id = window:window_id()
    local now = os.time()

    local st = leader_state[id] or { active = false, last = 0 }
    local active = window:leader_is_active()

    -- Toast only on transition into leader mode, and debounce.
    if active and not st.active and (now - (st.last or 0)) >= 2 then
      leader_toast(window, pane)
      st.last = now
    end

    st.active = active
    leader_state[id] = st
  end)
end

local function show_help(window, pane)
  local choices = {
    { id = "split_h", label = "Pane: split horizontal (Leader + |)" },
    { id = "split_v", label = "Pane: split vertical (Leader + -)" },
    { id = "pane_left", label = "Pane: focus left (Leader + h)" },
    { id = "pane_down", label = "Pane: focus down (Leader + j)" },
    { id = "pane_up", label = "Pane: focus up (Leader + k)" },
    { id = "pane_right", label = "Pane: focus right (Leader + l)" },
    { id = "resize_left", label = "Pane: resize left (Leader + H)" },
    { id = "resize_down", label = "Pane: resize down (Leader + J)" },
    { id = "resize_up", label = "Pane: resize up (Leader + K)" },
    { id = "resize_right", label = "Pane: resize right (Leader + L)" },
    { id = "tab_new", label = "Tab: new tab (Leader + n)" },
    { id = "tab_prev", label = "Tab: previous tab (Leader + [)" },
    { id = "tab_next", label = "Tab: next tab (Leader + ])" },
    { id = "close_pane", label = "Pane: close current (Leader + x)" },
    { id = "zoom", label = "Pane: zoom (Leader + z)" },
    { id = "fullscreen", label = "Window: fullscreen (Leader + f)" },
    { id = "ws_switch", label = "Workspace: switcher (Leader + w)" },
    { id = "ws_create", label = "Workspace: create (Leader + W)" },
    { id = "ws_delete", label = "Workspace: delete current (Leader + d)" },
    { id = "sess_save", label = "Session: save (Leader + s)" },
    { id = "sess_restore", label = "Session: restore (Leader + r)" },
    { id = "ssh_picker", label = "Ops: SSH host picker (Leader + g)" },
    { id = "notes", label = "Notes: open scratch notes (Leader + N)" },
    { id = "cmd_palette", label = "WezTerm: command palette (Ctrl+Shift+P)" },
    { id = "ai", label = "WezTerm: AI assistant (Ctrl+Shift+A)" },
  }

  window:perform_action(
    act.InputSelector({
      title = "Leader Help",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(win, p, id, label)
        if not id or id == "" then
          return
        end

        local map = {
          split_h = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
          split_v = act.SplitVertical({ domain = "CurrentPaneDomain" }),
          pane_left = act.ActivatePaneDirection("Left"),
          pane_down = act.ActivatePaneDirection("Down"),
          pane_up = act.ActivatePaneDirection("Up"),
          pane_right = act.ActivatePaneDirection("Right"),
          resize_left = act.AdjustPaneSize({ "Left", 5 }),
          resize_down = act.AdjustPaneSize({ "Down", 5 }),
          resize_up = act.AdjustPaneSize({ "Up", 5 }),
          resize_right = act.AdjustPaneSize({ "Right", 5 }),
          tab_new = act.SpawnTab("CurrentPaneDomain"),
          tab_prev = act.ActivateTabRelative(-1),
          tab_next = act.ActivateTabRelative(1),
          close_pane = act.CloseCurrentPane({ confirm = true }),
          zoom = act.TogglePaneZoomState,
          fullscreen = act.ToggleFullScreen,
          ws_switch = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
        }

        if map[id] then
          win:perform_action(map[id], p)
          return
        end

        -- For actions defined in other modules: trigger by sending the keystroke
        -- so we don't duplicate logic (resurrect, ssh picker, notes, etc).
        local send = {
          ws_create = act.SendKey({ key = "W", mods = "LEADER|SHIFT" }),
          ws_delete = act.SendKey({ key = "d", mods = "LEADER" }),
          sess_save = act.SendKey({ key = "s", mods = "LEADER" }),
          sess_restore = act.SendKey({ key = "r", mods = "LEADER" }),
          ssh_picker = act.SendKey({ key = "g", mods = "LEADER" }),
          notes = act.SendKey({ key = "N", mods = "LEADER|SHIFT" }),
          cmd_palette = act.SendKey({ key = "P", mods = "CTRL|SHIFT" }),
          ai = act.SendKey({ key = "A", mods = "CTRL|SHIFT" }),
        }
        if send[id] then
          win:perform_action(send[id], p)
        end
      end),
    }),
    pane
  )
end

function M.apply(config)
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = "?",
    mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      show_help(window, pane)
    end),
  })
end

return M
