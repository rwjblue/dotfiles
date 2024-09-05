local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = 'Tokyo Night'

config.font = wezterm.font({ family = 'Berkeley Mono', weight = "Regular" })
config.font_size = 12

config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }

-- native fullscreen is SOOOO slow (the animation kills me)
config.native_macos_fullscreen_mode = false

config.audible_bell = "Disabled"

config.keys = {
  { key = 'L', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action.ToggleFullScreen,
  },
}
for i = 1, 9 do
  -- {
  --     key = "1",
  --     mods = "CMD",
  --     action = wezterm.action({ SendKey = { key = "F1" } }),
  -- },
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CMD",
    action = wezterm.action({ SendKey = { key = "F" .. i } }),
  })
end

-- use this along with Ctrl-Shift-L to see the debug messages for what actual keycodes were detected
--config.debug_key_events = true

-- ideally we can set this based on the current monitor, but since we can't
-- access wezterm.gui.screen() at the moment in the config just hard code :/
config.initial_rows = 90
config.initial_cols = 300

-- Follow https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
-- to install a wezterm terminfo to $HOME/.terminfo

config.term = "wezterm"


local status_ok, local_config = pcall(require, 'local_config_overrides')
if status_ok and type(local_config) == 'function' then
  local_config(config)
end

return config
