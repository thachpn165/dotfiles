local wezterm = require("wezterm")

local M = {}

-- Catppuccin Mocha colors
local colors = {
  base = "#1e1e2e",
  mantle = "#181825",
  surface0 = "#313244",
  surface1 = "#45475a",
  text = "#cdd6f4",
  subtext0 = "#a6adc8",
  mauve = "#cba6f7",
  blue = "#89b4fa",
  green = "#a6e3a1",
  peach = "#fab387",
  red = "#f38ba8",
  yellow = "#f9e2af",
  teal = "#94e2d5",
}

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

local function push_right(elements, bg, fg, text)
  table.insert(elements, { Foreground = { Color = bg } })
  table.insert(elements, { Text = SOLID_RIGHT_ARROW })
  table.insert(elements, { Background = { Color = bg } })
  table.insert(elements, { Foreground = { Color = fg } })
  table.insert(elements, { Text = " " .. text .. " " })
end

function M.setup()
  -- Left status: LEADER indicator + workspace name
  wezterm.on("update-status", function(window, pane)
    local left = {}

    -- LEADER indicator
    if window:leader_is_active() then
      table.insert(left, { Background = { Color = colors.mauve } })
      table.insert(left, { Foreground = { Color = colors.base } })
      table.insert(left, { Text = " " .. wezterm.nerdfonts.md_lightning_bolt .. " LEADER " })
      table.insert(left, { Background = { Color = colors.blue } })
      table.insert(left, { Foreground = { Color = colors.mauve } })
      table.insert(left, { Text = SOLID_LEFT_ARROW })
    else
      table.insert(left, { Background = { Color = colors.blue } })
    end

    -- Workspace name
    local workspace = window:active_workspace()
    table.insert(left, { Foreground = { Color = colors.base } })
    table.insert(left, { Text = " " .. wezterm.nerdfonts.md_folder .. " " .. workspace .. " " })
    table.insert(left, { Background = { Color = "none" } })
    table.insert(left, { Foreground = { Color = colors.blue } })
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

    -- Date/time (short format)
    local date = wezterm.strftime("%d/%m %H:%M")
    push_right(right, colors.mauve, colors.base, wezterm.nerdfonts.md_clock .. " " .. date)

    window:set_right_status(wezterm.format(right))
  end)
end

return M
