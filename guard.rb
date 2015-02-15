clearing :on if Guard::VERSION.to_s.include?('2.12')
notification :tmux,
  display_message: true,
  color_location: %w(pane-border-fg pane-active-border-fg)
