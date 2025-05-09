# dotfiles

My own personal, highly subjective set of tools to help me do my dev work.

As for context: I've been (mostly) a backend developer for web apps in my career. At some point I turned my terminal into an IDE of sorts, and never looked back.

## History
* [Est. 2011](https://github.com/davelens/dotfiles/commits/master/?since=2011-05-27&until=2011-05-31)
* Started on macos, now used on both macos and WSL2 (currently Arch) instances
* My professional dev work shifted over the years from PHP, to Ruby, to Elixir
* Included my Vim setup until 2020, when I moved it to [a separate repository](https://github.com/davelens/dotvim)

## Installation
You can clone this repo wherever you want, but this assumes you'll save the files in `~/.dotfiles`:
```bash
git clone git@github.com:davelens/dotfiles.git ~/.dotfiles
~/.dotfiles/setup/install
```
### User-specific configuration and Bitwarden
Because [Bitwarden](https://bitwarden.com/) is my password manager of choice, I tailored the installer to ask you if you want to use `bitwarden-cli` to retrieve some data related to your Github account and `~/.gitconfig`.

This is entirely **optional**; you will still get prompted to enter the data manually.

### Uninstall
```bash
~/.dotfiles/setup/uninstall
```

## Custom bash scripts
You can call custom bash scripts using the `utility` command, which is also aliased to `u`:
```bash
Usage: utility <category> <command> [<args>...]
```
It comes with completion on both category and command to help you find what you're looking for.

### Linking your own homebrew scripts
You can symlink a directory with some of your personal scripts into `bin/utilities/`, and `utility` will pick them up automagically.

## macos defaults
`config/macos/defaults.sh` is a large file full of subjective macos system settings and overrides. All credit here should be given to [@mathiasbynens](https://mths.be/macos), who painstakingly compiled and maintains it.

**Disclaimer**: There is no revert option, so use this at your own discretion:

```bash
source ~/.dotfiles/config/macos/defaults.sh
```

