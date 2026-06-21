# Agent Notes

## First Moves
- Treat this as a personal dotfiles repo. Keep edits narrow and avoid rewriting unrelated shell/editor config.
- Do not print secrets from local config files. It is fine to inspect structure and variable names when needed.
- Check `git status --short` before editing; preserve user changes.

## Commands
```bash
bash tests/install-smoke.sh
shellcheck install.sh tests/install-smoke.sh
./install.sh brew
./install.sh brew --yes
./install.sh brew-base
./install.sh brew-cleanup
./install.sh brew-upgrade
./install.sh brew-schedule
./install.sh brew-unschedule
```

## Repo Map
- `install.sh`: main installer and utility entry point.
- `Brewfile`: base Homebrew bundle.
- `Brewfile.personal`: personal app/tool profile loaded by `./install.sh brew`.
- `Brewfile.security`: security/networking profile loaded by `./install.sh brew`.
- `.config/nvim/`: LazyVim-based Neovim config.
- `.config/doom/`: Doom Emacs config linked after Doom install.
- `tests/install-smoke.sh`: offline smoke coverage for symlink, backup, and idempotency behavior.

## Install Behavior
- `./install.sh` without args opens an interactive module picker.
- `--yes` changes preview/check operations into applying operations for Brew modules.
- `brew`, `brew-base`, `brew-cleanup`, `brew-upgrade`, schedule modules, and `iterm2` are macOS-only.
- Link operations back up existing real files/directories as `*.backup.<timestamp>` before replacing them.

## Gotchas
- Run the smoke test as `bash tests/install-smoke.sh`; the file is tracked non-executable.
- `brew` combines `Brewfile` plus every `Brewfile.*` except `Brewfile.lock.json`.
- `brew-upgrade` previews without `--yes`; with `--yes` it also upgrades managed Go, npm, uv, Krew, and VSCode/Cursor entries.
- Scheduled brew upgrade installs a LaunchAgent for Sunday 10:00 and uses `pinentry-mac` only when sudo is needed.
