local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function split_ws(s)
  local t = {}
  for w in s:gmatch("%S+") do
    table.insert(t, w)
  end
  return t
end

local function is_real_host(token)
  if token == "*" then
    return false
  end
  if token:find("[%*%?]") then
    return false
  end
  return true
end

local function add_host(set, list, host)
  if not set[host] then
    set[host] = true
    table.insert(list, host)
  end
end

local function parse_ssh_config_file(path, set, list)
  local content = read_file(path)
  if not content then
    return
  end

  for line in content:gmatch("[^\r\n]+") do
    -- Strip comments
    line = line:gsub("%s*#.*$", "")
    local host_spec = line:match("^%s*[Hh][Oo][Ss][Tt]%s+(.+)$")
    if host_spec then
      for _, token in ipairs(split_ws(host_spec)) do
        if is_real_host(token) then
          add_host(set, list, token)
        end
      end
    end
  end
end

local function gather_ssh_hosts()
  local home = wezterm.home_dir
  local set = {}
  local list = {}

  local main = home .. "/.ssh/config"
  if file_exists(main) then
    parse_ssh_config_file(main, set, list)

    -- Best-effort include support: many setups use ~/.ssh/config.d/*.conf
    local glob = wezterm.glob
    if glob then
      local includes = {}
      for _, p in ipairs(glob(home .. "/.ssh/config.d/*")) do
        table.insert(includes, p)
      end
      for _, p in ipairs(glob(home .. "/.ssh/config.d/**/*.conf")) do
        table.insert(includes, p)
      end
      for _, p in ipairs(includes) do
        if file_exists(p) then
          parse_ssh_config_file(p, set, list)
        end
      end
    end
  end

  table.sort(list)
  return list
end

local function load_host_classification()
  local ok, cfg = pcall(require, "ssh_hosts")
  if ok and type(cfg) == "table" then
    return cfg
  end
  return { production = {}, staging = {} }
end

local function classify_host(host)
  local cfg = load_host_classification()
  for _, pat in ipairs(cfg.production or {}) do
    if host:find(pat, 1, true) then
      return "production"
    end
  end
  for _, pat in ipairs(cfg.staging or {}) do
    if host:find(pat, 1, true) then
      return "staging"
    end
  end
  return "default"
end

local function build_shell_command(host, server_type)
  -- Use bash for portability (macOS + most Linux).
  -- Use base64 with both BSD and GNU variants.
  local host_q = host:gsub("'", [["'"']])
  local type_q = server_type:gsub("'", [["'"']])

  local script = table.concat({
    "HOST='" .. host_q .. "'",
    "TYPE='" .. type_q .. "'",
    "b64() { (printf %s \"$1\" | base64 -w0 2>/dev/null) || (printf %s \"$1\" | base64 | tr -d '\\n'); }",
    "printf '\\033]1337;SetUserVar=%s=%s\\007' SSH_HOST \"$(b64 \"$HOST\")\"",
    "printf '\\033]1337;SetUserVar=%s=%s\\007' SERVER_TYPE \"$(b64 \"$TYPE\")\"",
    "printf '\\033]1;%s\\033\\\\' \"$HOST\"",
    "exec ssh \"$HOST\"",
  }, "; ")

  return { "bash", "-lc", script }
end

function M.apply(config)
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "g",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local hosts = gather_ssh_hosts()
      if #hosts == 0 then
        window:toast_notification("WezTerm", "No SSH hosts found in ~/.ssh/config", nil, 3000)
        return
      end

      local choices = {}
      for _, h in ipairs(hosts) do
        local st = classify_host(h)
        local label = h
        if st ~= "default" then
          label = h .. " (" .. st .. ")"
        end
        table.insert(choices, { id = h, label = label })
      end

      window:perform_action(
        act.InputSelector({
          title = "SSH",
          fuzzy = true,
          choices = choices,
          action = wezterm.action_callback(function(win, p, id, label)
            if not id or id == "" then
              return
            end
            local st = classify_host(id)
            win:perform_action(
              act.SpawnCommandInNewTab({
                args = build_shell_command(id, st),
              }),
              p
            )
          end),
        }),
        pane
      )
    end),
  })
end

return M

