-- PREFACE:
-- For years I've been used to iTerm2's non-native full screen mode on macos.
-- The config below is as close as I can get to that.
local wezterm = require('wezterm')
local config = wezterm.config_builder()
local platforms = {
  macos = wezterm.target_triple:find('apple'),
  windows = wezterm.target_triple:find('windows'),
}
local function is_process_running(name)
  local handle = io.popen("pgrep '" .. name .. "'")
  if not handle then
    return false
  end

  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

-- Defaults!
config.max_fps = 120 -- Fixes the (s)low default of 60, this feels snappier.
config.enable_tab_bar = false
config.color_scheme = 'Catppuccin Mocha'
config.font_size = 14.0

config.window_padding = {
  left = 10,
  right = 10,
  top = 0,
  bottom = 0,
}

-- stylua: ignore
config.keys = {
  { key = 'r', mods = 'CMD|SHIFT', action = wezterm.action.ReloadConfiguration },
  -- Disable most keybinds associated with tab management, I don't use em.
  { mods = 'SUPER',         key = '1', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(0)
  { mods = 'SUPER',         key = '2', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(1)
  { mods = 'SUPER',         key = '3', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(2)
  { mods = 'SUPER',         key = '4', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(3)
  { mods = 'SUPER',         key = '5', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(4)
  { mods = 'SUPER',         key = '6', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(5)
  { mods = 'SUPER',         key = '7', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(6)
  { mods = 'SUPER',         key = '8', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(7)
  { mods = 'SUPER',         key = '9', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTab(-1)
  { mods = 'SUPER',         key = 't', action = wezterm.action.DisableDefaultAssignment }, -- SpawnTab
  { mods = 'SUPER',         key = '{', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SUPER',         key = '}', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  { mods = 'SHIFT | SUPER', key = '{', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SHIFT | SUPER', key = '}', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  { mods = 'SHIFT | SUPER', key = '[', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(-1)
  { mods = 'SHIFT | SUPER', key = ']', action = wezterm.action.DisableDefaultAssignment }, -- ActivateTabRelative(1)
  -- Disable the wezterm search; I have more control with the bash default.
  { mods = 'SUPER',         key = 'f', action = wezterm.action.DisableDefaultAssignment }, -- Search(CurrentSelectionOrEmptyString)
}

if platforms.macos then
  config.native_macos_fullscreen_mode = false

  local window_frame_table = {
    border_top_color = 'black',
    border_bottom_height = '0',
  }

  -- No title bar or notch space reservation necessary when Aerospace runs.
  if is_process_running('AeroSpace') then
    config.window_background_opacity = 0.9
    config.macos_window_background_blur = 20
    config.window_decorations = 'RESIZE'
    config.window_padding = { left = 14, right = 14, top = 18, bottom = 0 }
  else
    window_frame_table.border_top_height = '.7cell'
  end

  -- Make it so my external monitors that run at 72 dpi don't do anything with
  -- the fonts. On high dpi screens though, the slight line height/cell width
  -- adjustments are welcome.
  wezterm.on('window-resized', function(window, _)
    local dims = window:get_dimensions()

    if dims.dpi > 72 then
      config.line_height = 1.03
      config.cell_width = 1.01
    end
  end)

  config.window_frame = window_frame_table
  config.font_size = 16.0
  config.font = wezterm.font_with_fallback({
    { family = 'Monaco', weight = 'Regular' },
    { family = 'Hack Nerd Font' },
    { family = 'Apple Color Emoji' },
  })

  -- CMD+Enter is how I've been triggering full screen for years.
  config.keys = {
    -- stylua: ignore
    { mods = 'ALT', key = 'Enter', action = wezterm.action.DisableDefaultAssignment, },
    { mods = 'SUPER', key = 'Enter', action = wezterm.action.ToggleFullScreen },
  }
end

-- Load platform specific configurations
if platforms.windows then
  -- The default for me is "wslhost.exe", not very descriptive.
  wezterm.on('format-window-title', function()
    return 'Wezterm'
  end)

  config.line_height = 1.08
  -- stylua: ignore
  config.default_prog = {
    'wsl.exe', '-d', 'Arch', '-u', 'davelens',
    '--', 'bash', '-c', 'cd ~ && exec bash',
  }

  config.font = wezterm.font_with_fallback({
    { family = 'NotoMono NF', weight = 'Regular' },
    { family = 'Hack Nerd Font' },
  })
end

if platforms.linux then
  config.font = wezterm.font_with_fallback({
    { family = 'NotoMono NF', weight = 'Regular' },
    { family = 'Hack Nerd Font' },
  })
end

return config
