## Installation
#### Install

    git clone git@github.com:davelens/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh

#### Uninstall

    cd ~/.dotfiles && ./uninstall.sh

## Configuration
- Your personal info in .dotfiles/gitconfig
- If you use irssi (or plan to): Your desired servers, channels, highlights and aliases in .dotfiles/irssi/config
- The take_screenshot command in .dotfiles/bash/macos uploads a screenshot to my webspace and puts the link in my clipboard. If you want to use this as well, just replace my SSH-host with your own.
- If you're a tmux + iTerm2 user, you'll want to set a non-ASCII text custom font to display powerline symbols in tmux's status bar. Download such a font [here](https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf), then in your ITerm2 profile settings in the Text tab, look for ```Use a different font for non-ASCII text``` and select the desired font in the dropdown.

## macOS defaults
I use an abundant number of macOS setting overrides. These are subjective, so some might seem odd, strange or unwanted for you. That is why it requires a separate install instruction. A big credit here should be given to [@mathiasbynens](http://github.com/mathiasbynens), as he keeps maintaining his list for every major macOS release. If you want to give it a go, just copy-paste the line below in your shell. Use at your own discretion though, there is no reset:

	source ~/.dotfiles/macos/defaults-overrides

## iTerm2




## Tmux
### Statusline "Segments"
My tmux config now parses small bits of information to the left of the date in the status-right section. They are inspired by and/or stolen from the (now unmaintained) [tmux-powerline repo](https://github.com/erikw/tmux-powerline):

* Laptop battery status. Done with [richo/battery](https://github.com/richo/battery)
* Unread e-mail count. Caveats:
  * Reads user/pass from your ```.netrc```.
  * You need to configure which servers to check [here](https://github.com/davelens/dotfiles/blob/master/bin/tmux/mailcount.sh#L6).
* Current track playing in Spotify. Taken from [jdxcode/tmux-spotify-info](https://github.com/jdxcode/tmux-spotify-info)

## No vimrc?
In april 2020 I finally took the proper time to move my vim setup to a separate
repository, to be found [here](https://github.com/davelens/dotvim).
