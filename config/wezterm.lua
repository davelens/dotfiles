-- PREFACE:
-- For years I've been used to iTerm2's non-native full screen mode on macos.
-- The config below is as close as I can get to that.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local platforms = {
  macos = wezterm.target_triple:find("apple"),
  windows = wezterm.target_triple:find("windows")
}

-- Defaults!
config.max_fps = 144 -- Fixes the (s)low default of 60, this feels snappier.
config.enable_tab_bar = false
config.color_scheme = 'nord'
config.font_size = 14.0

config.window_frame = {
  border_bottom_height = '0',
}

config.window_padding = {
  left = 10,
  right = 10,
  top = 0,
  bottom = 0,
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
}

if platforms.macos then
  config.native_macos_fullscreen_mode = false

  config.window_frame = {
    border_top_height = '.7cell',
    border_top_color = 'black',
  }

  config.line_height = 1.03
  config.cell_width = 1.01
  config.font_size = 16.0
  config.font = wezterm.font_with_fallback {
    { family = "Monaco", weight = "Regular" },
    { family = "Hack Nerd Font" },
    { family = "Apple Color Emoji" },
  } 

  -- CMD+Enter is how I've been triggering full screen for years.
  config.keys = {
    { mods = 'ALT', key = 'Enter', action = wezterm.action.ToggleFullScreen }, -- ToggleFullScreen
    { mods = 'SUPER', key = 'Enter', action = wezterm.action.DisableDefaultAssignment },
  }
end

-- Load platform specific configurations
if platforms.windows then
  -- The default for me is "wslhost.exe", not very descriptive.
  wezterm.on('format-window-title', function() return "Wezterm" end)

  config.line_height = 1.08
  config.prefer_egl = true
  config.enable_wayland = false
  config.default_prog = {
    "wsl.exe", "-d", "Arch", "-u", "davelens", "--", "bash", "-c", "cd ~ && exec bash"
  }

  config.font_size = 14.0
  config.font = wezterm.font_with_fallback {
    { family = "NotoMono NF", weight = "Regular" },
    { family = "Hack Nerd Font" },
  }
end

return config
