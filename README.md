## Installation
#### Install
```bash
git clone git@github.com:davelens/dotfiles.git ~/.dotfiles
~/.dotfiles/install
```

#### Uninstall
```bash
~/.dotfiles/uninstall
```

## Configuration
At the top of `~/.gitconfig` you'll have to edit the `[user]` section with your GitHub user and e-mail address (and optionally your GPG signing key).

Somewhere in the future this information will be read from ENV vars, but for now just edit that file and you should be set.

## Custom bash scripts
You can call custom bash scripts using the `utility` command, which is also aliased to `u`:
```bash
Usage: utility <category> <command> [<args>...]
```
It comes with autocompletion on both category and command to help you find what you're looking for.

### Linking your own homebrew scripts
You can symlink a directory with some of your personal scripts into `bin/utilities/`, and `utility` will pick them up automagically.

## Optional neovim config
In april 2020 I finally took the proper time to move my vim setup to [a separate
repository](https://github.com/davelens/dotvim).

## macos defaults
`macos/defaults` is a large file full of subjective macos system settings and overrides. All credit here should be given to [@mathiasbynens](https://mths.be/macos), who painstakingly compiled and maintains it.

**Disclaimer**: There is no revert option, so use this at your own discretion:

```bash
source ~/.dotfiles/macos/defaults
```

