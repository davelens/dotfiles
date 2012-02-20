# Install
Run the following line in your shell:

    git clone https://github.com/davelens/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh *

# Uninstall
If you're sick of my dotfiles, you can copy-paste the following in your shell: 

	cd ~/.dotfiles && ./uninstall.sh

# Mac OS X defaults
I use an abundant number of OSX setting overrides. Most of these are widely recognized as optimal settings, but some might seem odd, strange or unwanted for you. That is why it requires a separate install instruction. If you want to give it a go, just copy-paste the line below in your shell:

	source ~/.dotfiles/osx/defaults-overwrite

You can use the provided reset to restore to OSX default settings. Note that this also overrides any custom settings you defined yourself, so use with caution!
