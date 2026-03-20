local wezterm = require("wezterm")
local M = {}

local function get_resolved_scheme(config)
  local scheme_name = config.color_scheme
  if config.color_schemes and scheme_name and config.color_schemes[scheme_name] then
    return config.color_schemes[scheme_name]
  end

  local builtin_schemes = wezterm.color.get_builtin_schemes()
  if scheme_name and builtin_schemes[scheme_name] then
    return builtin_schemes[scheme_name]
  end

  return wezterm.color.get_default_colors()
end

local function get_effective_color(config, scheme, key)
  if config.colors and config.colors[key] then
    return config.colors[key]
  end

  if scheme and scheme[key] then
    return scheme[key]
  end

  local defaults = wezterm.color.get_default_colors()
  return defaults[key]
end

local function derive_split_color(config)
  if config.colors and config.colors.split then
    return config.colors.split
  end

  local scheme = get_resolved_scheme(config)
  local bg = wezterm.color.parse(get_effective_color(config, scheme, "background"))
  local _, _, bg_lightness = bg:hsla()
  local tab_bar = scheme.tab_bar or {}
  local active_tab = tab_bar.active_tab or {}

  local candidates = {
    scheme.split,
    scheme.cursor_border,
    scheme.cursor_bg,
    active_tab.bg_color,
    active_tab.fg_color,
    get_effective_color(config, scheme, "foreground"),
  }

  for _, value in ipairs(candidates) do
    if value then
      local candidate = wezterm.color.parse(value)
      if candidate:contrast_ratio(bg) >= 1.8 then
        return candidate
      end

      for _, factor in ipairs({ 0.12, 0.2, 0.3, 0.42, 0.55 }) do
        local adjusted = bg_lightness < 0.5 and candidate:lighten(factor) or candidate:darken(factor)
        if adjusted:contrast_ratio(bg) >= 1.8 then
          return adjusted
        end
      end
    end
  end

  return bg_lightness < 0.5 and bg:lighten(0.72) or bg:darken(0.72)
end

function M.apply(config)
  -- Color scheme
  config.color_scheme = "Catppuccin Mocha"

  -- Font: Menlo with Nerd Font fallback for icons
  config.font = wezterm.font_with_fallback({
    "Menlo",
    "MesloLGS Nerd Font Mono",
  })
  config.font_size = 16.0

  -- Window appearance
  config.window_background_opacity = 0.8
  config.macos_window_background_blur = 20
  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  }

  -- Slightly boost text brightness so dim ANSI colors stay readable on the
  -- translucent, blurred background.
  config.foreground_text_hsb = {
    brightness = 1.08,
  }

  -- Tab bar
  config.use_fancy_tab_bar = true
  config.tab_bar_at_bottom = true
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 25

  -- Keep the tab bar font styling, but let the active color scheme control
  -- the fancy tab bar colors so `local.lua` theme overrides propagate cleanly.
  config.window_frame = {
    font = require("wezterm").font("MesloLGS Nerd Font Mono", { weight = "Bold" }),
    font_size = 12.0,
  }

  -- Leave the scheme colors untouched so `local.lua` can override the theme
  -- with `config.color_scheme = "..."` or a loaded scheme file.
  -- config.colors = {
  --   -- Improve text contrast on semi-transparent background.
  --   foreground = "#e6e9ef",
  --   background = "#1e1e2e",
  --   -- Raise ANSI black/bright-black so dim/meta text is still readable.
  --   ansi = { "#6c7086", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#bac2de" },
  --   brights = { "#a6adc8", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#f2f5ff" },
  --   tab_bar = {
  --     background = "#1e1e2e",
  --     active_tab = {
  --       bg_color = "#cba6f7",
  --       fg_color = "#1e1e2e",
  --       intensity = "Bold",
  --     },
  --     inactive_tab = {
  --       bg_color = "#313244",
  --       fg_color = "#cdd6f4",
  --     },
  --     inactive_tab_hover = {
  --       bg_color = "#45475a",
  --       fg_color = "#cdd6f4",
  --     },
  --     new_tab = {
  --       bg_color = "#313244",
  --       fg_color = "#cdd6f4",
  --     },
  --     new_tab_hover = {
  --       bg_color = "#45475a",
  --       fg_color = "#cdd6f4",
  --     },
  --   },
  -- }

  -- Keep non-focused panes readable when splitting windows.
  config.inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 1.0,
  }

  -- GPU acceleration
  config.front_end = "WebGpu"
  config.max_fps = 120

  -- Vietnamese IME support
  config.use_ime = true
  config.use_dead_keys = true
  config.macos_forward_to_ime_modifier_mask = "SHIFT"
  config.send_composed_key_when_left_alt_is_pressed = true
  config.send_composed_key_when_right_alt_is_pressed = true
  config.normalize_output_to_unicode_nfc = true

  -- Misc
  config.scrollback_lines = 10000
  config.default_cursor_style = "BlinkingBar"
  config.cursor_blink_rate = 500
end

function M.finalize(config)
  config.colors = config.colors or {}
  config.colors.split = derive_split_color(config)
end

return M
