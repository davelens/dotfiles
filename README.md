# Install
Run the following line in your shell:

    git clone git@github.com:davelens/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh *

# Uninstall
If you're sick of my dotfiles, you can copy-paste the following in your shell:

	cd ~/.dotfiles && ./uninstall.sh

# Settings you should change
- Your personal info in .dotfiles/gitconfig
- If you use irssi (or plan to): Your desired servers, channels, highlights and aliases in .dotfiles/irssi/config
- The take_screenshot command in .dotfiles/bash/osx uploads a screenshot to my webspace and puts the link in my clipboard. If you want to use this as well, just replace my SSH-host with your own.

# Mac OS X defaults
I use an abundant number of OSX setting overrides. These are subjective, so some might seem odd, strange or unwanted for you. That is why it requires a separate install instruction. A big credit here should be given to Matthias Bynens' collection of OSX defaults. If you want to give it a go, just copy-paste the line below in your shell:

	source ~/.dotfiles/osx/defaults-overrides

You can use the provided reset to restore to OSX default settings. Note that this also overrides any custom settings you defined yourself, so use with caution!

	source ~/.dotfiles/osx/defaults-reset
