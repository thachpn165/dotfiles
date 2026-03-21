local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function pick_editor_argv()
  -- Prefer $EDITOR, but it may include args (e.g. "nvim -u NONE").
  -- Use wezterm.shell_split when available so we can spawn without a shell.
  local editor = os.getenv("EDITOR")
  if editor and editor ~= "" then
    local ok, argv = pcall(function()
      return wezterm.shell_split(editor)
    end)
    if ok and type(argv) == "table" and #argv > 0 then
      return argv
    end
    -- Fallback: use just the first token
    local first = editor:match("^%s*(%S+)")
    if first and first ~= "" then
      return { first }
    end
  end

  if wezterm.which("nvim") then
    return { "nvim" }
  end
  if wezterm.which("vim") then
    return { "vim" }
  end
  return { "vi" }
end

local function notes_path()
  -- Keep it portable and under the same dir used by other wezterm state files.
  return wezterm.home_dir .. "/.local/share/wezterm/notes.md"
end

function M.apply(config)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "phys:N",
    mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local path = notes_path()
      local argv = pick_editor_argv()

      -- Ensure parent dir exists without relying on shell quoting.
      pcall(function()
        wezterm.run_child_process({ "mkdir", "-p", wezterm.home_dir .. "/.local/share/wezterm" })
      end)

      table.insert(argv, path)
      window:toast_notification("WezTerm", "Opening notes: " .. path, nil, 1500)
      window:perform_action(act.SpawnCommandInNewTab({ args = argv }), pane)
    end),
  })
end

return M
