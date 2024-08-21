local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night'

config.font = wezterm.font({ family = 'Berkeley Mono', weight = "Bold" })
config.font_size = 12.0
config.window_decorations = 'RESIZE'

return config
