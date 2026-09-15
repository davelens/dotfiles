# dotfiles

My own personal, highly subjective set of tools to help me do my dev work.

As for context: I've been (mostly) a backend developer for web apps in my career. At some point I turned my terminal into an IDE of sorts, and never looked back.

## History
* [Est. 2011](https://github.com/davelens/dotfiles/commits/master/?since=2011-05-27&until=2011-05-31)
* Initially made for macos, these days mostly used on Arch Linux
* My professional dev work shifted over the years from PHP, to Ruby and Elixir
* Included my Vim setup until 2020, when I moved it to [a separate repository](https://github.com/davelens/dotvim)

## Configuration installation

On a prepared machine (Bash 5, Git, Python and required filesystem tools), run
from your **stable** checkout; no initialized dotfiles shell is needed:

```bash
bash setup/check prerequisites
bash setup/install --select ''          # Core only; no packages or services
bash setup/check readiness              # Installed capabilities, not a live-session test
```

`bin/autoload/dots install [OPTIONS...]` and `dots check prerequisites|readiness`
forward directly to these entrypoints. Additions are `sway`, `macos-desktop`,
`wsl-integration`, `karabiner`, and `alfred`, on their applicable platforms.
`--select CSV` supplies the complete addition set. `--wezterm-destination PATH`
requests an explicit Windows-host copy; without a destination, no host write occurs.

Choices resolve as arguments > designated `DOTS_INSTALL_SELECTION` /
`DOTS_INSTALL_WEZTERM_DESTINATION` environment inputs > saved choices > defaults.
Only `install --save` persists the narrow choices block in the trusted
`$XDG_CONFIG_HOME/dots/env`; unrelated/private values are preserved. HOME and XDG
roots come from the invoking environment. There is no working-directory `.env` lookup.

`install --check` checks configuration conflicts without applying them.
Matching unowned artifacts require `--adopt EXACT_PATH`; conflicting content needs
`--replace EXACT_PATH` and a successful backup. `setup/uninstall` removes only
unchanged owned artifacts; restoration is separate via `setup/restore --backup ID`.
Failures preserve completed work, private data and backups, not an automatic rollback.

### Remote acquisition

Download and review `setup/remote/init.sh` from this repository before running it:

```bash
bash setup/remote/init.sh --destination /absolute/dotfiles -- --select ''
```

The standalone script clones the public source and pinned submodules, then runs
configuration installation directly. Git is required: no archive fallback,
package installation, identity prompts, or implicit update. Nonempty non-repository
destinations are refused. Existing checkouts are preserved: use their `setup/install`
explicitly; use the checked update route below for incoming revisions.

### Checked updates

`dots update` always includes the actual invoked checkout (including symlink/worktree
entrypoints), plus repositories under `$REPO_NAMESPACE/davelens/dot*` when configured.
`dots update --repo /absolute/other-repo` selects explicit additional repositories
instead of that discovery. `--select CSV` and `--wezterm-destination PATH` are transient;
ordinary updates retain saved choices. Update never saves choices or provisions.

Only clean, attached, upstream-tracking repositories can fast-forward. Dirty/untracked
work, divergent history and uninitialized/moved/dirty recursive submodules block their
repository. Dotbot follows the superproject pin, never its own upstream. Submodule
removal/type changes require explicit preparation. Git hooks are not run by update.

Incoming source and pinned recursive submodules are checked in a private
`$XDG_STATE_HOME/dots/update-*/source` clone. You can run the same read-only check:

```bash
bash /candidate/source/setup/check candidate --install-root /absolute/stable/dotfiles
```

Candidate code/manifests/requirements supply the source; expected live links and
external helper registrations use the stable checkout. No live links point into the
candidate. Checking creates no ownership locks, configuration, caches or saved choices.
Trusted `dots/env` is read as Bash, not sandboxed against deliberately side-effecting code.

Rejected checks retain their exact candidate and print its revision, config path,
inspection command and an explicit preparation route, when mise requirements need it:
`bash /absolute/dotsys/shared/mise/init.sh --config /retained/source/config/mise/config.toml`.
Update does not execute that command. Only the exact recorded run area may be cleaned;
the output gives its optional cleanup command. `latest` checks installed availability,
not upstream freshness.

After rechecking source/index/branch and machine/conflict observations, update performs
a clean fast-forward, pinned submodule update, configuration reinstall and readiness
check. Later failures report **partial advancement**, not rollback. Independent requested
repositories continue; every summary includes old/new revisions and outcome, and any
failure makes the batch nonzero. This is not an all-file/repository transaction or proof
against runtime regressions; real-host portability acceptance is still pending.

### Provisioning and optional tools

[Dotsys](https://github.com/davelens/dotsys) owns software and service provisioning.
`dots setup` delegates to its existing `shared/install.sh`, defaulting to a sibling
`dotsys` checkout. Set `DOTSYS_REPO_HOME=/absolute/stable/dotsys` for another location;
a missing delegate fails without cloning or provisioning anything.

- `dots setup --dotsys arch|void|macos|wsl`: staged provisioning through readiness,
  then selected activation. `--arch` / `--void` are compatibility aliases.
- `dots setup --dotvim --dotshell`: only requested acquisition/registration on a
  prepared machine, not packages, configuration installation or activation.
- `dots setup --dotfiles`: configuration only (direct `dots install` needs no dotsys).
- `--full-machine`: explicitly adds the previous broad machine workflows.

Setup passes options unchanged, including `--dotfiles-root`, `--dotvim-root`,
`--dotshell-root`, `--home`, `--user`, `--xdg-{config,data,state,cache,bin}-home`,
configuration choices/approvals and separate `--helper-adopt` / `--helper-replace`.
The default `--dotfiles-root` is the invoked dotfiles checkout. See
`dots setup --help` for the dotsys interface. `utility brew init` (also
`setup/brew/init.sh`) delegates to dotsys with `--skip-bundles` / `--no-confirm`;
dotfiles no longer maintains a competing Brewfile.

Identity/authentication remains explicit: private Git identity/signing preferences
belong in `$XDG_CONFIG_HOME/git/config.env`; `gh auth login`, `ssh-add`, and
`utility misc bitwarden` are separate opt-in workflows. Missing optional commands
are diagnosed, never automatically installed. `setup/remote/configure_env.sh`
prints identity guidance only; it does not write private env or request credentials.

Automated fixtures are not real-host acceptance: macOS, Arch, Void and Windows-host
WSL validation remains pending. Never install from implementation/test worktrees.

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

