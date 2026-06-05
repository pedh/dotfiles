#!/usr/bin/env bash

set -e

DOTFILES_PATH="$(git rev-parse --show-toplevel)"

MODULES=(git dircolors zshrc emacs vim nvim tmux gpg mbsync iterm2 rime)
MACOS_ONLY=(iterm2 rime)

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

install_git() {
  ln -sf "${DOTFILES_PATH}/.git-config" "${HOME}/.gitconfig"
}

install_dircolors() {
  local dircolors_cmd="dircolors"
  type -p dircolors || dircolors_cmd="gdircolors"
  ${dircolors_cmd} -b "${DOTFILES_PATH}/.dircolors" > "${HOME}/.LS_COLORS"
}

install_zshrc() {
  local source_line='source ~/.dotfiles/.zshrc'
  grep -qxF "${source_line}" "${HOME}/.zshrc" ||
    echo "${source_line}" >> "${HOME}/.zshrc"
}

install_emacs() {
  git -C "${HOME}/.config/emacs" pull ||
    git clone --depth 1 https://github.com/doomemacs/doomemacs \
      "${HOME}/.config/emacs"
  "${HOME}/.config/emacs/bin/doom" install --no-config
  if [[ -e "${HOME}/.config/doom" && ! -L "${HOME}/.config/doom" ]]; then
    read -p "The doom config already exists, delete it?(y/N)" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rm -rf "${HOME}/.config/doom"
    else
      exit 0
    fi
  fi
  ln -sf "${DOTFILES_PATH}/.config/doom" "${HOME}/.config/"
  "${HOME}/.config/emacs/bin/doom" sync
}

install_vim() {
  ln -sf "${DOTFILES_PATH}/.vim" "${HOME}/"
  ln -sf "${DOTFILES_PATH}/.vimrc" "${HOME}/"
}

install_nvim() {
  ln -sf "${DOTFILES_PATH}/.config/nvim" "${HOME}/.config/"
}

install_tmux() {
  git -C "${HOME}/.tmux" pull ||
    git clone https://github.com/gpakosz/.tmux.git "${HOME}/.tmux"
  ln -sf "${HOME}/.tmux/.tmux.conf" "${HOME}/"
  cp "${HOME}/.tmux/.tmux.conf.local" "${HOME}/"
}

install_gpg() {
  ln -sf "${DOTFILES_PATH}/.gnupg/gpg.conf" "${HOME}/.gnupg/"
  ln -sf "${DOTFILES_PATH}/.gnupg/gpg-agent.conf" "${HOME}/.gnupg/"
  ln -sf "${DOTFILES_PATH}/.gnupg/pinentry-auto" "${HOME}/.gnupg/"
}

install_mbsync() {
  ln -sf "${DOTFILES_PATH}/.mbsyncrc" "${HOME}/"
}

install_iterm2() {
  defaults write -app iterm "PrefsCustomFolder" -string "${DOTFILES_PATH}/.iterm"
  defaults write -app iterm "LoadPrefsFromCustomFolder" -bool true
  defaults write -app iterm "NoSyncNeverRemindPrefsChangesLostForFile_selection" -int 2
}

install_rime() {
  git clone https://github.com/rime/plum.git "${HOME}/.plum"
  bash "${HOME}/.plum/rime-install" iDvel/rime-ice:others/recipes/full
}

run_module() {
  local mod="$1"
  can_run "$mod" || return 0
  echo "==> Installing $mod"
  "install_${mod}"
}

interactive_menu() {
  local available=()
  for mod in "${MODULES[@]}"; do
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
  read -p "Select modules (e.g. 1 3 5, 1-5, or a): " selection

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

if [[ $# -gt 0 ]]; then
  for mod in "$@"; do
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
