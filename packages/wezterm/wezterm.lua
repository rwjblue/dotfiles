local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local function is_retina()
  for _, monitor in ipairs(wezterm.gui.screens()) do
    if monitor.dpi > 100 then
      return true
    end
  end
  return false
end


config.audible_bell = "Disabled"
config.color_scheme = 'Tokyo Night'

-- TODO: figure out if we are being displayed on a retina screen, and use Regular instead of Bold here
config.font = wezterm.font({ family = 'Berkeley Mono', weight = "Bold" })
config.font_size = 12.0

config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }
config.dpi = 72 -- this is the DPI for my widescreen monitor
--config.dpi = wezterm.gui.get_dpi_for_monitor(wezterm.gui.screens().active)

-- FIXME: calling wezterm.gui.screens() within config seems to make wezterm unresponsive
--local screens = wezterm.gui.screens()


-- native fullscreen is SOOOO slow (the animation kills me)
config.native_macos_fullscreen_mode = false

config.keys = {
  { key = 'L', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
  {
    key = 'Enter',
    mods = 'CMD',
    action = wezterm.action.ToggleFullScreen,
  },

  -- disable the default action for CMD+1, CMD+2, etc
  { key = '1', mods = 'CMD',        action = wezterm.action.DisableDefaultAssignment },
  { key = '2', mods = 'CMD',        action = wezterm.action.DisableDefaultAssignment },
  { key = '3', mods = 'CMD',        action = wezterm.action.DisableDefaultAssignment },
  -- { key = "1", mods = "CMD",        action = wezterm.action { SendKey = { key = "1", mods = "CTRL" } } },
  -- { key = "2", mods = "CMD",        action = wezterm.action { SendKey = { key = "2", mods = "CTRL" } } },
  -- { key = "3", mods = "CMD",        action = wezterm.action { SendKey = { key = "3", mods = "CTRL" } } },
  -- { key = "4", mods = "CMD", action = wezterm.action { SendKey = { key = "4", mods = "CTRL" } } },
  -- { key = "5", mods = "CMD", action = wezterm.action { SendKey = { key = "5", mods = "CTRL" } } },
  -- { key = "6", mods = "CMD", action = wezterm.action { SendKey = { key = "6", mods = "CTRL" } } },
  -- { key = "7", mods = "CMD", action = wezterm.action { SendKey = { key = "7", mods = "CTRL" } } },
  -- { key = "8", mods = "CMD", action = wezterm.action { SendKey = { key = "8", mods = "CTRL" } } },
  -- { key = "9", mods = "CMD", action = wezterm.action { SendKey = { key = "9", mods = "CTRL" } } },

}

-- use this along with Ctrl-Shift-L to see the debug messages for what actual keycodes were detected
--config.debug_key_events = true

-- ideally we can set this based on the current monitor, but since we can't
-- access wezterm.gui.screen() at the moment in the config just hard code :/
config.initial_rows = 90
config.initial_cols = 300

return config
