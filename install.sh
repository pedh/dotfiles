#!/usr/bin/env bash

set -e

DOTFILES_PATH="$(git rev-parse --show-toplevel)"
ASSUME_YES=false

INSTALL_MODULES=(brew git dircolors zshrc emacs vim nvim tmux gpg mbsync iterm2)
UTILITY_MODULES=(brew-base brew-cleanup)
MODULES=("${INSTALL_MODULES[@]}" "${UTILITY_MODULES[@]}")
MACOS_ONLY=(brew brew-base brew-cleanup iterm2)

is_macos() {
  [[ "$(uname)" == "Darwin" ]]
}

is_macos_only() {
  local mod="$1"
  for m in "${MACOS_ONLY[@]}"; do
    [[ "$m" == "$mod" ]] && return 0
  done
  return 1
}

can_run() {
  local mod="$1"
  if is_macos_only "$mod" && ! is_macos; then
    echo "Skipping $mod (macOS only)"
    return 1
  fi
  return 0
}

backup_path() {
  local target="$1"
  local backup
  local counter=1

  backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${target}.backup.$(date +%Y%m%d%H%M%S).${counter}"
    counter=$((counter + 1))
  done

  printf '%s\n' "$backup"
}

link_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      return 0
    fi
    mv "$target" "$(backup_path "$target")"
  elif [[ -e "$target" ]]; then
    mv "$target" "$(backup_path "$target")"
  fi

  ln -s "$source" "$target"
}

collect_brew_bundle_files() {
  BREW_BUNDLE_FILES=("${DOTFILES_PATH}/Brewfile")

  local profile_file

  for profile_file in "${DOTFILES_PATH}"/Brewfile.*; do
    [[ -f "$profile_file" ]] || continue
    [[ "$(basename "$profile_file")" == "Brewfile.lock.json" ]] && continue
    BREW_BUNDLE_FILES+=("$profile_file")
  done
}

brew_bundle_with_profiles() {
  local subcommand="$1"
  shift

  collect_brew_bundle_files || return 1
  cat "${BREW_BUNDLE_FILES[@]}" | brew bundle "$subcommand" --file=- "$@"
}

brew_bundle_check_with_profiles() {
  brew_bundle_with_profiles check --verbose --no-upgrade
}

install_brew_base() {
  if [[ "$ASSUME_YES" == true ]]; then
    brew bundle install --no-upgrade --file="${DOTFILES_PATH}/Brewfile"
    return
  fi

  echo "Checking base Brewfile only. Pass --yes to install."
  brew bundle check --verbose --no-upgrade --file="${DOTFILES_PATH}/Brewfile"
}

install_brew() {
  if [[ "$ASSUME_YES" == true ]]; then
    brew_bundle_with_profiles install --no-upgrade
    return
  fi

  echo "Checking Brewfile profiles only. Pass --yes to install."
  brew_bundle_check_with_profiles
}

install_brew_cleanup() {
  if [[ "$ASSUME_YES" == true ]]; then
    brew_bundle_with_profiles cleanup --all --force
    return
  fi

  if ! brew_bundle_with_profiles cleanup --all; then
    echo "Review the cleanup preview above."
    echo "Run ./install.sh brew-cleanup --yes to apply it."
  fi
}

install_git() {
  local target="${HOME}/.gitconfig"

  if ! is_macos; then
    link_path "${DOTFILES_PATH}/.git-config" "$target"
    return
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "${DOTFILES_PATH}/.git-config" ]]; then
      rm "$target"
    else
      mv "$target" "$(backup_path "$target")"
    fi
  elif [[ -e "$target" ]]; then
    if ! { [[ -f "$target" ]] && grep -qxF "	path = ${DOTFILES_PATH}/.git-config" "$target"; }; then
      mv "$target" "$(backup_path "$target")"
    fi
  fi

  cat > "$target" <<EOF
[include]
	path = ${DOTFILES_PATH}/.git-config
[credential]
	helper = osxkeychain
EOF
}

install_dircolors() {
  local dircolors_cmd
  if type -p dircolors > /dev/null; then
    dircolors_cmd="dircolors"
  elif type -p gdircolors > /dev/null; then
    dircolors_cmd="gdircolors"
  else
    echo "dircolors or gdircolors is required. Install coreutils first." >&2
    return 1
  fi
  ${dircolors_cmd} -b "${DOTFILES_PATH}/.dircolors" > "${HOME}/.LS_COLORS"
}

install_zshrc() {
  local source_line='source ~/.dotfiles/.zshrc'
  touch "${HOME}/.zshrc"
  grep -qxF "${source_line}" "${HOME}/.zshrc" ||
    echo "${source_line}" >> "${HOME}/.zshrc"
}

install_emacs() {
  mkdir -p "${HOME}/.config"
  git -C "${HOME}/.config/emacs" pull ||
    git clone --depth 1 https://github.com/doomemacs/doomemacs \
      "${HOME}/.config/emacs"
  "${HOME}/.config/emacs/bin/doom" install --no-config --no-env
  link_path "${DOTFILES_PATH}/.config/doom" "${HOME}/.config/doom"
  "${HOME}/.config/emacs/bin/doom" sync
}

install_vim() {
  link_path "${DOTFILES_PATH}/.vim" "${HOME}/.vim"
  link_path "${DOTFILES_PATH}/.vimrc" "${HOME}/.vimrc"
}

install_nvim() {
  link_path "${DOTFILES_PATH}/.config/nvim" "${HOME}/.config/nvim"
}

install_tmux() {
  git -C "${HOME}/.tmux" pull ||
    git clone https://github.com/gpakosz/.tmux.git "${HOME}/.tmux"
  link_path "${HOME}/.tmux/.tmux.conf" "${HOME}/.tmux.conf"
  if [[ ! -e "${HOME}/.tmux.conf.local" ]]; then
    cp "${HOME}/.tmux/.tmux.conf.local" "${HOME}/"
  fi
}

install_gpg() {
  link_path "${DOTFILES_PATH}/.gnupg/gpg.conf" "${HOME}/.gnupg/gpg.conf"
  link_path "${DOTFILES_PATH}/.gnupg/gpg-agent.conf" "${HOME}/.gnupg/gpg-agent.conf"
  link_path "${DOTFILES_PATH}/.gnupg/pinentry-auto" "${HOME}/.gnupg/pinentry-auto"
}

install_mbsync() {
  link_path "${DOTFILES_PATH}/.mbsyncrc" "${HOME}/.mbsyncrc"
}

install_iterm2() {
  defaults write -app iterm "PrefsCustomFolder" -string "${DOTFILES_PATH}/.iterm"
  defaults write -app iterm "LoadPrefsFromCustomFolder" -bool true
  defaults write -app iterm "NoSyncNeverRemindPrefsChangesLostForFile_selection" -int 2
}

run_module() {
  local mod="$1"
  local fn="install_${mod//-/_}"
  can_run "$mod" || return 0
  echo "==> Running $mod"
  "$fn"
}

interactive_menu() {
  local available=()
  for mod in "${INSTALL_MODULES[@]}"; do
    if is_macos_only "$mod" && ! is_macos; then
      continue
    fi
    available+=("$mod")
  done

  echo "Available modules:"
  for i in "${!available[@]}"; do
    printf "  %2d) %s\n" $((i + 1)) "${available[$i]}"
  done
  printf "   a) all\n"
  echo ""
  read -r -p "Select modules (e.g. 1 3 5, 1-5, or a): " selection

  if [[ "$selection" == "a" ]]; then
    for mod in "${available[@]}"; do
      run_module "$mod"
    done
    return
  fi

  local indices=()
  for part in $selection; do
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      for ((i = BASH_REMATCH[1]; i <= BASH_REMATCH[2]; i++)); do
        indices+=($((i - 1)))
      done
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      indices+=($((part - 1)))
    fi
  done

  for idx in "${indices[@]}"; do
    if [[ $idx -ge 0 && $idx -lt ${#available[@]} ]]; then
      run_module "${available[$idx]}"
    fi
  done
}

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --yes)
      ASSUME_YES=true
      ;;
    --)
      ;;
    --*)
      echo "Unknown option: $arg"
      exit 1
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [[ ${#ARGS[@]} -gt 0 ]]; then
  for mod in "${ARGS[@]}"; do
    if printf '%s\n' "${MODULES[@]}" | grep -qx "$mod"; then
      run_module "$mod"
    else
      echo "Unknown module: $mod"
      echo "Available: ${MODULES[*]}"
      exit 1
    fi
  done
else
  interactive_menu
fi
