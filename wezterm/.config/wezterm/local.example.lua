local wezterm = require("wezterm")

local M = {}

function M.apply(config)
  -- Personal overrides only. Copy this file to `local.lua`, then tweak
  -- anything below without touching tracked files in this repo.
  -- Browse built-in themes at https://wezterm.org/colorschemes/index.html
  -- and set the exact scheme name here.
  config.color_scheme = "Tokyo Night"
  config.font_size = 15.0
  config.window_background_opacity = 0.92

  -- Only enable this if the font is installed on your machine.
  -- config.font = wezterm.font_with_fallback({
  --   "JetBrainsMono Nerd Font",
  --   "MesloLGS Nerd Font Mono",
  -- })
end

return M
