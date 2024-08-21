local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night'

config.font = wezterm.font({ family = 'Berkeley Mono', weight = "Bold" })
config.font_size = 12.0
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true

-- native fullscreen is SOOOO slow (the animation kills me)
config.native_macos_fullscreen_mode = false
config.keys = {
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action.ToggleFullScreen,
  },
}

return config
