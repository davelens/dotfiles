-- User configuration for luakit
-- Loaded automatically at the end of the default rc.lua.

local window = require('window')
local modes = require('modes')
local webview = require('webview')

-- Move the status/URL bar to the top of the window.
-- The default build order is: tablist, webview, bar_layout (bottom).
-- We reorder to: bar_layout (top), tablist, webview.
window.add_signal('build', function(w)
  w.layout:remove(w.tablist.widget)
  w.layout:remove(w.menu_tabs)
  w.layout:remove(w.bar_layout)

  w.layout:pack(w.bar_layout)
  w.layout:pack(w.tablist.widget)
  w.layout:pack(w.menu_tabs, { expand = true, fill = true })
end)

-- Dark mode: CSS invert+hue-rotate applied via a WebKit stylesheet object.
-- Disabled by default; toggle with Alt+D across all open webviews.
local dark_css = stylesheet({
  source = [[
  html {
    filter: invert(0.9) hue-rotate(180deg) !important;
    background: #111 !important;
  }
  img, video, picture, canvas, svg, [style*="background-image"] {
    filter: invert(1) hue-rotate(180deg) !important;
  }
]],
})

local dark_enabled = false

-- Apply dark mode state to a webview.
local function apply_dark(view)
  view.stylesheets[dark_css] = dark_enabled
end

-- Apply to every new webview as it's created.
webview.add_signal('init', function(view)
  apply_dark(view)
end)

-- Toggle dark mode on all open webviews.
modes.add_binds('normal', {
  {
    '<Mod1-d>',
    'Toggle dark mode.',
    function(w)
      dark_enabled = not dark_enabled
      for _, ww in pairs(window.bywidget) do
        for i = 1, ww.tabs:count() do
          apply_dark(ww.tabs[i])
        end
      end
      w:notify('Dark mode ' .. (dark_enabled and 'enabled' or 'disabled'))
    end,
  },
})

-- Bitwarden: autofill credentials via the bw CLI.
-- Uses a helper script that handles vault unlock (prompting via foot terminal
-- if BW_SESSION is not set) and credential lookup. Runs asynchronously so the
-- UI stays responsive.
-- Bound to Ctrl+Shift+L.

-- Run a command asynchronously and capture its stdout via a temp file.
local function spawn_with_output(cmd, callback)
  local outfile = os.tmpname()
  local shfile = os.tmpname()
  local f = io.open(shfile, 'w')
  f:write(cmd .. ' > ' .. outfile .. ' 2>/dev/null\n')
  f:close()
  luakit.spawn('/bin/sh ' .. shfile, function(reason, status)
    local fh = io.open(outfile, 'r')
    local stdout = fh and fh:read('*a') or ''
    if fh then
      fh:close()
    end
    os.remove(outfile)
    os.remove(shfile)
    callback(status, stdout)
  end)
end

-- Escape a string for safe inclusion in a JavaScript string literal.
local function js_escape(s)
  return s:gsub('\\', '\\\\')
    :gsub("'", "\\'")
    :gsub('"', '\\"')
    :gsub('\n', '\\n')
end

-- Inject credentials into the active page's login form.
local function fill_credentials(w, username, password, domain)
  local js = string.format(
    [[
    (function() {
      var inputs = document.querySelectorAll('input');
      var filled = false;
      for (var i = 0; i < inputs.length; i++) {
        var el = inputs[i];
        var type = (el.getAttribute('type') || '').toLowerCase();
        var name = (el.getAttribute('name') || '').toLowerCase();
        var auto = (el.getAttribute('autocomplete') || '').toLowerCase();
        var nativeSet = Object.getOwnPropertyDescriptor(
          HTMLInputElement.prototype, 'value'
        ).set;

        if (type === 'email' || type === 'text' ||
            name === 'email' || name === 'username' || name === 'login' ||
            auto === 'username' || auto === 'email') {
          nativeSet.call(el, '%s');
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
          filled = true;
        } else if (type === 'password') {
          nativeSet.call(el, '%s');
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
          filled = true;
        }
      }
      return filled ? 'filled' : 'no-fields';
    })();
  ]],
    js_escape(username),
    js_escape(password)
  )

  w.view:eval_js(js, {
    callback = function(ret)
      if ret == 'filled' then
        w:notify('Bitwarden: credentials filled for ' .. domain)
      else
        w:error('Bitwarden: no login fields found on page')
      end
    end,
  })
end

modes.add_binds('normal', {
  {
    '<Control-Shift-l>',
    'Fill login from Bitwarden.',
    function(w)
      local uri = w.view.uri
      if not uri then
        w:error('No URI to match against')
        return
      end

      local domain = uri:match('^%w+://([^/]+)')
      if not domain then
        w:error('Cannot extract domain from URI')
        return
      end

      w:notify('Bitwarden: looking up ' .. domain .. '...')

      local helper = luakit.config_dir .. '/bw-fill'
      local cmd = string.format('%s %q', helper, domain)

      spawn_with_output(cmd, function(status, stdout)
        if status ~= 0 or stdout == '' then
          w:error('Bitwarden: no credentials found for ' .. domain)
          return
        end

        -- The helper outputs two lines: username, then password.
        local username, password = stdout:match('^([^\n]*)\n([^\n]*)')
        if not username or not password or username == '' then
          w:error('Bitwarden: could not parse credentials')
          return
        end

        fill_credentials(w, username, password, domain)
      end)
    end,
  },
})
