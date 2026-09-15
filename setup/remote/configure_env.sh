#!/usr/bin/env bash
# Retained as explicit identity guidance, never called by configuration install.
cat <<'EOF'
Identity/authentication is separate from public dotfiles installation.
Edit your private $XDG_CONFIG_HOME/git/config.env explicitly to set Git user.name,
user.email and optional signing preferences (setup/git/gitconfig.env.template is
an example, not an automatically applied template).
Use gh auth login, ssh-add, or utility misc bitwarden only when explicitly wanted
and after installing their optional commands. No credentials are required here.
Keep private overrides in $XDG_CONFIG_HOME/dots/env; this route never writes it.
Use dots install --select CSV --save to save only installer choices.
EOF
