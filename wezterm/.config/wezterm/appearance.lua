local M = {}

function M.apply(config)
  -- Color scheme
  config.color_scheme = "Catppuccin Mocha"

  -- Font: Menlo with Nerd Font fallback for icons
  local wezterm = require("wezterm")
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

  -- Tab bar
  config.use_fancy_tab_bar = true
  config.tab_bar_at_bottom = true
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_max_width = 25

  -- Catppuccin Mocha tab bar colors
  config.window_frame = {
    font = require("wezterm").font("MesloLGS Nerd Font Mono", { weight = "Bold" }),
    font_size = 12.0,
    active_titlebar_bg = "#1e1e2e",
    inactive_titlebar_bg = "#181825",
  }

  config.colors = {
    -- Improve text contrast on semi-transparent background.
    foreground = "#e6e9ef",
    background = "#1e1e2e",
    -- Raise ANSI black/bright-black so dim/meta text is still readable.
    ansi = { "#6c7086", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#bac2de" },
    brights = { "#a6adc8", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#cba6f7", "#94e2d5", "#f2f5ff" },
    tab_bar = {
      background = "#1e1e2e",
      active_tab = {
        bg_color = "#cba6f7",
        fg_color = "#1e1e2e",
        intensity = "Bold",
      },
      inactive_tab = {
        bg_color = "#313244",
        fg_color = "#cdd6f4",
      },
      inactive_tab_hover = {
        bg_color = "#45475a",
        fg_color = "#cdd6f4",
      },
      new_tab = {
        bg_color = "#313244",
        fg_color = "#cdd6f4",
      },
      new_tab_hover = {
        bg_color = "#45475a",
        fg_color = "#cdd6f4",
      },
    },
  }

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

return M
