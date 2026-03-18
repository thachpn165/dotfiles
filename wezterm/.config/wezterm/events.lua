local wezterm = require("wezterm")
local mux = wezterm.mux

local M = {}

-- Window size persistence
local state_dir = wezterm.home_dir .. "/.local/share/wezterm"
local state_file = state_dir .. "/window-size.json"

local function save_window_size(window)
  local dims = window:get_dimensions()
  if dims.is_full_screen then
    return
  end
  local data = wezterm.json_encode({
    width = dims.pixel_width,
    height = dims.pixel_height,
  })
  os.execute("mkdir -p " .. state_dir)
  local f = io.open(state_file, "w")
  if f then
    f:write(data)
    f:close()
  end
end

local function load_window_size()
  local f = io.open(state_file, "r")
  if not f then
    return nil
  end
  local data = f:read("*a")
  f:close()
  local ok, size = pcall(wezterm.json_parse, data)
  if ok then
    return size
  end
  return nil
end

-- Catppuccin Mocha colors
local colors = {
  base = "#1e1e2e",
  mantle = "#181825",
  surface0 = "#313244",
  text = "#cdd6f4",
  mauve = "#cba6f7",
  blue = "#89b4fa",
  green = "#a6e3a1",
  peach = "#fab387",
  red = "#f38ba8",
  yellow = "#f9e2af",
  muted_red = "#53394a",
  muted_yellow = "#534f3a",
}

-- Get tab title (prefer explicit title, fallback to process name)
local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end
  return tab_info.active_pane.title
end

function M.setup()
  -- Custom tab title formatting (with SSH server type coloring)
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local index = tab.tab_index + 1
    local title = tab_title(tab)
    local server_type = tab.active_pane.user_vars.SERVER_TYPE or ""

    -- Truncate title if too long
    local max_title = max_width - 4
    if #title > max_title then
      title = title:sub(1, max_title - 1) .. "\u{2026}"
    end

    if tab.is_active then
      local bg = colors.mauve
      if server_type == "production" then
        bg = colors.red
      elseif server_type == "staging" then
        bg = colors.yellow
      end
      return {
        { Background = { Color = bg } },
        { Foreground = { Color = colors.base } },
        { Text = " " .. index .. ": " .. title .. " " },
      }
    end

    local bg = hover and colors.surface0 or colors.mantle
    if server_type == "production" then
      bg = colors.muted_red
    elseif server_type == "staging" then
      bg = colors.muted_yellow
    end
    return {
      { Background = { Color = bg } },
      { Foreground = { Color = colors.text } },
      { Text = " " .. index .. ": " .. title .. " " },
    }
  end)

  -- Rename default workspace to "main"
  wezterm.on("update-status", function(window, pane)
    if mux.get_active_workspace() == "default" then
      mux.rename_workspace("default", "main")
    end
  end)

  -- Save window size on resize
  wezterm.on("window-resized", function(window, pane)
    save_window_size(window)
  end)

  -- Restore window size on startup
  wezterm.on("gui-startup", function(cmd)
    local size = load_window_size()
    local tab, pane, window = mux.spawn_window(cmd or {})
    if size then
      window:gui_window():set_inner_size(size.width, size.height)
    end
  end)
end

return M
