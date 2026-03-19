local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("appearance").apply(config)
require("keybindings").apply(config)
require("statusbar").setup()
require("events").setup()
require("workspaces").apply(config)
require("ai").apply(config)
require("ssh_picker").apply(config)
require("notes").apply(config)
require("leader_hints").apply(config)
require("leader_hints").setup()

local ok, local_override = pcall(require, "local")
if ok and type(local_override) == "table" and type(local_override.apply) == "function" then
  local_override.apply(config)
end

return config
