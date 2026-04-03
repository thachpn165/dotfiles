local wezterm = require("wezterm")
local ai_usage = require("ai_usage")

local M = {}

-- Cache git info for 5 seconds
local git_cache = { branch = "", user = "", last_check = 0, cwd = "" }

local function get_git_info(pane)
  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return "", ""
  end

  local cwd = cwd_uri.file_path or ""
  if cwd == "" then
    return "", ""
  end

  local now = os.time()
  if now - git_cache.last_check < 5 and cwd == git_cache.cwd then
    return git_cache.branch, git_cache.user
  end

  local branch = ""
  local user = ""

  local ok_branch, stdout_branch = wezterm.run_child_process({
    "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD",
  })
  if ok_branch then
    branch = stdout_branch:gsub("%s+", "")
  end

  local ok_user, stdout_user = wezterm.run_child_process({
    "git", "-C", cwd, "config", "user.name",
  })
  if ok_user then
    user = stdout_user:gsub("%s+", "")
  end

  git_cache.branch = branch
  git_cache.user = user
  git_cache.last_check = now
  git_cache.cwd = cwd
  return branch, user
end

-- Powerline separator
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

local function get_scheme_colors(window)
  local config = window:effective_config()
  local schemes = wezterm.color.get_builtin_schemes()
  local scheme_name = config.color_scheme
  local scheme = nil

  if config.color_schemes and scheme_name and config.color_schemes[scheme_name] then
    scheme = config.color_schemes[scheme_name]
  elseif scheme_name and schemes[scheme_name] then
    scheme = schemes[scheme_name]
  else
    scheme = {}
  end

  local ansi = scheme.ansi or {}
  local tab_bar = scheme.tab_bar or {}
  local active_tab = tab_bar.active_tab or {}
  local inactive_tab = tab_bar.inactive_tab or {}
  local hover_tab = tab_bar.inactive_tab_hover or inactive_tab

  local background = scheme.background or "#1e1e2e"
  local foreground = scheme.foreground or "#cdd6f4"
  local tab_active_bg = active_tab.bg_color or scheme.cursor_bg or ansi[6] or "#89b4fa"
  local tab_active_fg = active_tab.fg_color or background
  local tab_inactive_bg = inactive_tab.bg_color or background
  local tab_inactive_fg = inactive_tab.fg_color or foreground
  local tab_hover_bg = hover_tab.bg_color or tab_inactive_bg

  return {
    base = background,
    text = foreground,
    surface0 = tab_inactive_bg,
    surface1 = tab_hover_bg,
    accent = tab_active_bg,
    accent_fg = tab_active_fg,
    tab_inactive_fg = tab_inactive_fg,
    blue = ansi[5] or tab_active_bg,
    green = ansi[3] or foreground,
    peach = ansi[6] or foreground,
    red = ansi[2] or foreground,
    yellow = ansi[4] or foreground,
    teal = ansi[7] or foreground,
  }
end

local function push_right(elements, bg, fg, text)
  table.insert(elements, { Foreground = { Color = bg } })
  table.insert(elements, { Text = SOLID_RIGHT_ARROW })
  table.insert(elements, { Background = { Color = bg } })
  table.insert(elements, { Foreground = { Color = fg } })
  table.insert(elements, { Text = " " .. text .. " " })
end

local function get_workspace_name(window)
  local ok_mux_window, mux_window = pcall(function()
    return window:mux_window()
  end)
  if ok_mux_window and mux_window then
    local ok_workspace, workspace = pcall(function()
      return mux_window:get_workspace()
    end)
    if ok_workspace and workspace and workspace ~= "" then
      return workspace
    end
  end

  local ok_active, active_workspace = pcall(function()
    return window:active_workspace()
  end)
  if ok_active and active_workspace and active_workspace ~= "" then
    return active_workspace
  end

  local ok_global, global_workspace = pcall(function()
    return wezterm.mux.get_active_workspace()
  end)
  if ok_global and global_workspace and global_workspace ~= "" then
    return global_workspace
  end

  return "main"
end

function M.setup()
  -- Left status: LEADER indicator + workspace name
  wezterm.on("update-status", function(window, pane)
    local colors = get_scheme_colors(window)
    local left = {}

    -- LEADER indicator
    if window:leader_is_active() then
      table.insert(left, { Background = { Color = colors.accent } })
      table.insert(left, { Foreground = { Color = colors.accent_fg } })
      table.insert(left, { Text = " " .. wezterm.nerdfonts.md_lightning_bolt .. " LEADER " })
      table.insert(left, { Background = { Color = colors.blue } })
      table.insert(left, { Foreground = { Color = colors.accent } })
      table.insert(left, { Text = SOLID_LEFT_ARROW })
    else
      table.insert(left, { Background = { Color = colors.blue } })
    end

    -- Workspace name
    local workspace = get_workspace_name(window)
    table.insert(left, { Background = { Color = colors.surface0 } })
    table.insert(left, { Foreground = { Color = colors.tab_inactive_fg } })
    table.insert(left, { Text = " " .. workspace .. " " })
    table.insert(left, { Background = { Color = "none" } })
    table.insert(left, { Foreground = { Color = colors.surface0 } })
    table.insert(left, { Text = SOLID_LEFT_ARROW })

    window:set_left_status(wezterm.format(left))

    -- Right status
    local right = {}
    table.insert(right, { Background = { Color = "none" } })

    -- SSH host (shown for all SSH connections)
    local vars = pane:get_user_vars()
    local ssh_host = vars.SSH_HOST or ""
    if ssh_host ~= "" then
      local server_type = vars.SERVER_TYPE or ""
      local ssh_color = colors.peach
      if server_type == "production" then
        ssh_color = colors.red
      elseif server_type == "staging" then
        ssh_color = colors.yellow
      end
      push_right(right, colors.surface0, ssh_color, wezterm.nerdfonts.md_server .. " " .. ssh_host)
    end

    -- Git user + branch
    local branch, git_user = get_git_info(pane)
    if git_user ~= "" then
      push_right(right, colors.surface0, colors.teal, wezterm.nerdfonts.md_account .. " " .. git_user)
    end
    if branch ~= "" then
      push_right(right, colors.surface0, colors.green, wezterm.nerdfonts.dev_git_branch .. " " .. branch)
    end

    -- AI tool usage / activity
    for _, segment in ipairs(ai_usage.get_segments(pane)) do
      local segment_color = colors.blue
      if segment.key == "claude" then
        segment_color = colors.peach
      end
      push_right(right, colors.surface0, segment_color, segment.text)
    end

    -- Date/time (short format)
    local date = wezterm.strftime("%d/%m %H:%M")
    push_right(right, colors.accent, colors.accent_fg, wezterm.nerdfonts.md_clock .. " " .. date)

    window:set_right_status(wezterm.format(right))
  end)
end

return M
