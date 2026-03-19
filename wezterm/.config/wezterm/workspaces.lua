local wezterm = require("wezterm")
local act = wezterm.action

local M = {}
local state_dir = wezterm.home_dir .. "/.local/share/wezterm/resurrect/"
local main_workspace = "main"

local function list_saved_states()
  local choices = {}
  local state_types = { "workspace", "window", "tab" }

  for _, state_type in ipairs(state_types) do
    local cmd = string.format('find "%s%s" -maxdepth 1 -type f -name "*.json" 2>/dev/null | sort', state_dir, state_type)
    local handle = io.popen(cmd)
    if handle then
      for path in handle:lines() do
        local file_name = path:match("([^/]+)%.json$")
        if file_name then
          table.insert(choices, {
            id = state_type .. "/" .. file_name,
            label = string.format("%s: %s", state_type, file_name),
          })
        end
      end
      handle:close()
    end
  end

  return choices
end

local function save_workspace_state(resurrect)
  local ok, result = pcall(function()
    local state = resurrect.workspace_state.get_workspace_state()
    resurrect.state_manager.save_state(state)
    resurrect.state_manager.write_current_state(state.workspace, "workspace")
    return state.workspace
  end)

  if ok then
    return true, result
  end

  wezterm.log_error("Failed to save workspace state: " .. tostring(result))
  return false, result
end

local function read_saved_workspace_name(file_path)
  local f = io.open(file_path, "r")
  if not f then
    return nil
  end

  local content = f:read("*a")
  f:close()

  local ok, decoded = pcall(wezterm.json_parse, content)
  if ok and decoded and decoded.workspace then
    return decoded.workspace
  end

  return nil
end

local function remove_file(path)
  local ok = os.remove(path)
  if ok then
    return true
  end

  local rm_ok = wezterm.run_child_process({ "rm", "-f", path })
  return rm_ok
end

local function delete_saved_workspace_state(workspace_name)
  local workspace_dir = state_dir .. "workspace"
  local deleted = false
  local candidates = {
    string.format("%s/%s.json", workspace_dir, workspace_name),
    string.format("%s/%s.json", workspace_dir, workspace_name:gsub("/", "+")),
  }

  for _, candidate in ipairs(candidates) do
    local ok = remove_file(candidate)
    if ok then
      deleted = true
    end
  end

  local cmd = string.format('find "%s" -maxdepth 1 -type f -name "*.json" 2>/dev/null', workspace_dir)
  local handle = io.popen(cmd)
  if handle then
    for file_path in handle:lines() do
      if read_saved_workspace_name(file_path) == workspace_name then
        local ok = remove_file(file_path)
        if ok then
          deleted = true
        end
      end
    end
    handle:close()
  end

  return deleted
end

local function collect_workspace_windows(workspace_name)
  local windows = {}
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    if mux_window:get_workspace() == workspace_name then
      table.insert(windows, {
        mux_window = mux_window,
        gui_window = mux_window:gui_window(),
      })
    end
  end
  return windows
end

local function get_or_create_main_window()
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    if mux_window:get_workspace() == main_workspace and mux_window:gui_window() then
      return mux_window:gui_window()
    end
  end

  local _, _, mux_window = wezterm.mux.spawn_window({ workspace = main_workspace })
  if mux_window then
    return mux_window:gui_window()
  end

  return nil
end

local function close_workspace_windows(workspace_windows)
  for _, entry in ipairs(workspace_windows) do
    if entry.gui_window then
      local tabs = entry.mux_window:tabs()
      for i = #tabs, 1, -1 do
        tabs[i]:activate()
        local active_pane = entry.mux_window:active_pane()
        if active_pane then
          entry.gui_window:perform_action(act.CloseCurrentTab({ confirm = false }), active_pane)
        end
      end
    end
  end
end

local function delete_current_workspace(window, pane, resurrect)
  local workspace_name = wezterm.mux.get_active_workspace()
  if workspace_name == main_workspace then
    window:toast_notification("WezTerm", "Refusing to delete workspace: main", nil, 4000)
    return
  end

  window:perform_action(
    act.PromptInputLine({
      description = wezterm.format({
        { Foreground = { Color = "#f38ba8" } },
        { Text = "Type workspace name to delete: " .. workspace_name },
      }),
      action = wezterm.action_callback(function(win, current_pane, line)
        if not line or line ~= workspace_name then
          win:toast_notification("WezTerm", "Workspace deletion cancelled", nil, 3000)
          return
        end

        local ok, err = pcall(function()
          local workspace_windows = collect_workspace_windows(workspace_name)
          local notify_window = get_or_create_main_window() or win

          local notify_pane = notify_window and notify_window:active_pane() or nil
          if notify_pane then
            notify_window:perform_action(act.SwitchToWorkspace({ name = main_workspace }), notify_pane)
          end

          close_workspace_windows(workspace_windows)
          wezterm.mux.set_active_workspace(main_workspace)

          local main_state = resurrect.workspace_state.get_workspace_state()
          resurrect.state_manager.save_state(main_state)
          resurrect.state_manager.write_current_state(main_state.workspace, "workspace")
          local deleted_state = delete_saved_workspace_state(workspace_name)
          local message = "Deleted workspace: " .. workspace_name
          if not deleted_state then
            message = message .. " (no saved session file found)"
          end

          notify_window:toast_notification("WezTerm", message, nil, 4000)
        end)

        if not ok then
          wezterm.log_error("Failed to delete workspace: " .. tostring(err))
          win:toast_notification("WezTerm", "Delete failed. Check debug overlay/log.", nil, 5000)
        end
      end),
    }),
    pane
  )
end

function M.apply(config)
  package.path = wezterm.config_dir .. "/?.lua;" .. package.path
  local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
  resurrect.state_manager.change_state_save_dir(state_dir)

  -- Periodic auto-save every 5 minutes
  resurrect.state_manager.periodic_save({
    interval_seconds = 300,
    save_workspaces = true,
    save_windows = false,
    save_tabs = true,
  })

  -- Save when switching workspace
  wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, pane, label)
    save_workspace_state(resurrect)
  end)

  wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, pane, label)
    save_workspace_state(resurrect)
  end)

  -- Add workspace keybindings to existing keys
  config.keys = config.keys or {}

  -- Leader + s: Save current workspace session
  table.insert(config.keys, {
    key = "s",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      local ok, result = save_workspace_state(resurrect)
      if ok then
        win:toast_notification("WezTerm", "Session saved: " .. result, nil, 3000)
      else
        win:toast_notification("WezTerm", "Save failed. Check debug overlay/log.", nil, 5000)
      end
    end),
  })

  -- Leader + r: Restore session (fuzzy finder)
  table.insert(config.keys, {
    key = "r",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      local choices = list_saved_states()
      if #choices == 0 then
        win:toast_notification("WezTerm", "No saved sessions found", nil, 4000)
        return
      end

      win:perform_action(
        act.InputSelector({
          title = "Restore Session",
          fuzzy = true,
          choices = choices,
          action = wezterm.action_callback(function(window, restore_pane, id, label)
            if not id or id == "" then
              return
            end

            local state_type = string.match(id, "^([^/]+)")
            local state_name = string.match(id, "([^/]+)$")

            local ok, err = pcall(function()
              local opts = {
                relative = true,
                restore_text = true,
                on_pane_restore = resurrect.tab_state.default_on_pane_restore,
              }

              if state_type == "workspace" then
                opts.spawn_in_workspace = true
                local state = resurrect.state_manager.load_state(state_name, "workspace")
                local workspace_name = state.workspace or state_name

                if not state.window_states or #state.window_states == 0 then
                  error("No saved windows found for workspace: " .. workspace_name)
                end

                resurrect.workspace_state.restore_workspace(state, opts)
                wezterm.mux.set_active_workspace(workspace_name)
                window:toast_notification("WezTerm", "Restored workspace: " .. workspace_name, nil, 4000)
              elseif state_type == "window" then
                local state = resurrect.state_manager.load_state(state_name, "window")
                resurrect.window_state.restore_window(restore_pane:window(), state, opts)
                window:toast_notification("WezTerm", "Restored window: " .. state_name, nil, 4000)
              elseif state_type == "tab" then
                local state = resurrect.state_manager.load_state(state_name, "tab")
                resurrect.tab_state.restore_tab(restore_pane:tab(), state, opts)
                window:toast_notification("WezTerm", "Restored tab: " .. state_name, nil, 4000)
              else
                error("Unsupported restore type: " .. tostring(state_type))
              end
            end)

            if not ok then
              wezterm.log_error("Failed to restore session: " .. tostring(err))
              window:toast_notification("WezTerm", "Restore failed. Check debug overlay/log.", nil, 5000)
            end
          end),
        }),
        pane
      )
    end),
  })

  table.insert(config.keys, {
    key = "d",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      delete_current_workspace(window, pane, resurrect)
    end),
  })
end

return M
