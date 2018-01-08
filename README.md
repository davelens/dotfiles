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

# Vim plugins
Remember to call ```:PluginInstall``` in Vim to install all included plugins, prior to all subsequent steps here.

## YouCompleteMe
YouCompleteMe (YCM) is a Vim plugin that requires a pre-compiled component. [See their installation instructions](https://github.com/Valloric/YouCompleteMe#installation) to get this sorted.

## vim-go
This plugin adds a plethora of support for the Go programming language. You will need to call ```:GoInstallBinaries``` from vim in order to install the necessary binaries in the ```~/.go``` directory.

## vim-airline
In order to display the fancy powerline symbols, you should locate and install the following font:
```bash
fonts/InputMono-Regular.ttf
```
Afterwards you **need** to configure your terminal to use InputMono as the non-ASCII font. If you're an iTerm2 user like myself, you can do this in the ```Preferences > Profiles > Text``` tab where you can check ```Use a different font for non-ASCII text``` and select the font in the dropdown.

If you don't wish to make use of the fancy powerline icons, comment out the following line in your ```.vimrc```:
```vimscript
let g:airline_powerline_fonts = 1
```

### iTerm2
You need to configure iTerm2 to use the InputMono font if your statusbar displays questionmarks instead of the required symbols.

### Mac OS X Yosemite
If you're on Yosemite the chances are that the YCM component failed to compile. I got this fixed with [a helpful SO answer](http://stackoverflow.com/questions/29529455/missing-c-header-debug-after-updating-osx-command-line-tools-6-3#answer-29576048).

# Tmux
## Statusline "Segments"
My tmux config now parses small bits of information to the left of the date in the status-right section. They are inspired by and/or stolen from the (now unmaintained) [tmux-powerline repo](https://github.com/erikw/tmux-powerline):

* Laptop battery status. Done via [richo/battery](https://github.com/richo/battery)
* Unread e-mail count. Caveats:
  * Reads user/pass from your ```.netrc```.
  * You need to configure which servers to check [here](https://github.com/davelens/dotfiles/blob/master/bin/tmux/mailcount.sh#L6).
* Current track playing in Spotify or iTunes. Taken from a StackOverflow post, can't remember which.

## There are strange symbols in my statusline, howcome?
In order to display the fancy powerline symbols, you should locate and install the following font:
```bash
fonts/InputMono-Regular.ttf
```
