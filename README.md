# Install
Run the following line in your shell:

    git clone git@github.com:davelens/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh

# Uninstall
If you're sick of my dotfiles, you can copy-paste the following in your shell:

	cd ~/.dotfiles && ./uninstall.sh

# ENV variables
The dotfiles will pick up a ```~/.env``` file and export its contents as env variables.

# Things you should change
- Your personal info in .dotfiles/gitconfig
- If you use irssi (or plan to): Your desired servers, channels, highlights and aliases in .dotfiles/irssi/config
- The take_screenshot command in .dotfiles/bash/macos uploads a screenshot to my webspace and puts the link in my clipboard. If you want to use this as well, just replace my SSH-host with your own.

# macOS defaults
I use an abundant number of macOS setting overrides. These are subjective, so some might seem odd, strange or unwanted for you. That is why it requires a separate install instruction. A big credit here should be given to [@mathiasbynens](http://github.com/mathiasbynens), as he keeps maintaining his list for every major macOS release. If you want to give it a go, just copy-paste the line below in your shell. Use at your own discretion though, there is no reset:

	source ~/.dotfiles/macos/defaults-overrides

#### iTerm2
If you're an iTerm2 user like myself, you can do this in your profile settings in the Text tab. Look for ```Use a different font for non-ASCII text``` and select the font in the dropdown.

# Tmux
## Statusline "Segments"
My tmux config now parses small bits of information to the left of the date in the status-right section. They are inspired by and/or stolen from the (now unmaintained) [tmux-powerline repo](https://github.com/erikw/tmux-powerline):

* Laptop battery status. Done with [richo/battery](https://github.com/richo/battery)
* Unread e-mail count. Caveats:
  * Reads user/pass from your ```.netrc```.
  * You need to configure which servers to check [here](https://github.com/davelens/dotfiles/blob/master/bin/tmux/mailcount.sh#L6).
* Current track playing in Spotify. Taken from [jdxcode/tmux-spotify-info](https://github.com/jdxcode/tmux-spotify-info)

# No vimrc?
In april 2020 I finally took the proper time to move my vim setup to a separate
repository, to be found [here](https://github.com/davelens/dotvim).
