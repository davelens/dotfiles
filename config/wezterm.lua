-- PREFACE:
-- For years I've been used to iTerm2's non-native full screen mode on macos.
-- The config below is as close as I can get to that.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- TODO: Two issues for me remain:
-- - [ ] Hack Nerd Font's glyphs are (too) small. How to scale them?
-- - [ ] It's very minor and nitpicking, but wezterm has a couple of pixels of
--       border bottom I can't seem to shake. Find out why.

config.max_fps = 240 -- Fixes the (s)low default of 60, this feels snappier.
config.native_macos_fullscreen_mode = false
config.enable_tab_bar = false
-- This provides us the same behaviour as iTerm2's top border
-- obfuscating the little camera inlay on macbooks nowadays.
-- Obviously I won't need that on other machines, so this should be
-- macos only (ideally macbook only, but I'll settle).
config.window_frame = {
  border_bottom_height = '0',
  border_top_height = '.7cell',
  border_top_color = 'black',
}
config.window_padding = {
  left = 10,
  right = 10,
  top = 0,
  bottom = 0,
}

-- Nord theme on Monaco with Hack has been my jam for a while now.
config.color_scheme = 'nord'
config.line_height = 1.03
config.cell_width = 1.01
config.font_size = 16.0
config.font = wezterm.font_with_fallback {
  { family = "Monaco", weight = "Regular" },
  { family = "Hack Nerd Font" },
  { family = "Apple Color Emoji" },
} 

config.keys = {
  -- Disable most keybinds associated with tab management, I don't use em.
  { mods = 'SUPER', key = '1', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(0)
  { mods = 'SUPER', key = '2', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(1)
  { mods = 'SUPER', key = '3', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(2)
  { mods = 'SUPER', key = '4', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(3)
  { mods = 'SUPER', key = '5', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(4)
  { mods = 'SUPER', key = '6', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(5)
  { mods = 'SUPER', key = '7', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(6)
  { mods = 'SUPER', key = '8', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(7)
  { mods = 'SUPER', key = '9', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(-1)
  { mods = 'SUPER', key = 't', action = wezterm.action.DisableDefaultAssignment }, -- SpawnTab
  { mods = 'SUPER', key = '{', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SUPER', key = '}', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  { mods = 'SHIFT | SUPER', key = '{', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SHIFT | SUPER', key = '}', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  { mods = 'SHIFT | SUPER', key = '[', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SHIFT | SUPER', key = ']', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  -- Disable the wezterm search; I have more control with the bash default.
  { mods = 'SUPER', key = 'f', action = wezterm.action.DisableDefaultAssignment }, -- Search(CurrentSelectionOrEmptyString)
  -- CMD/Win+Enter is how I've been triggering full screen for years.
  { mods = 'ALT', key = 'Enter', action = wezterm.action.DisableDefaultAssignment }, -- ToggleFullScreen
  { mods = 'SUPER', key = 'Enter', action = wezterm.action.ToggleFullScreen },
}

return config
