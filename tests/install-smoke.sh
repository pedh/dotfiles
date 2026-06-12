#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_symlink_to() {
  local link="$1"
  local target="$2"

  [[ -L "${link}" ]] || fail "${link} is not a symlink"
  [[ "$(readlink "${link}")" == "${target}" ]] ||
    fail "${link} points to $(readlink "${link}"), expected ${target}"
}

run_install() {
  local home="$1"
  shift

  HOME="${home}" "${ROOT}/install.sh" "$@"
}

new_home() {
  mktemp -d "${TMP_ROOT}/home.XXXXXX"
}

test_fresh_home_links_offline_modules() {
  local home
  home="$(new_home)"

  run_install "${home}" git zshrc mbsync vim nvim gpg

  if [[ "$(uname)" == "Darwin" ]]; then
    [[ -f "${home}/.gitconfig" ]] || fail "macOS gitconfig wrapper is missing"
    grep -qxF "	path = ${ROOT}/.git-config" "${home}/.gitconfig" ||
      fail "macOS gitconfig wrapper does not include repo config"
    grep -qxF "	helper = osxkeychain" "${home}/.gitconfig" ||
      fail "macOS gitconfig wrapper does not configure osxkeychain"
  else
    assert_symlink_to "${home}/.gitconfig" "${ROOT}/.git-config"
  fi
  assert_symlink_to "${home}/.mbsyncrc" "${ROOT}/.mbsyncrc"
  assert_symlink_to "${home}/.vim" "${ROOT}/.vim"
  assert_symlink_to "${home}/.vimrc" "${ROOT}/.vimrc"
  assert_symlink_to "${home}/.config/nvim" "${ROOT}/.config/nvim"
  assert_symlink_to "${home}/.gnupg/gpg.conf" "${ROOT}/.gnupg/gpg.conf"
  assert_symlink_to "${home}/.gnupg/gpg-agent.conf" "${ROOT}/.gnupg/gpg-agent.conf"
  assert_symlink_to "${home}/.gnupg/pinentry-auto" "${ROOT}/.gnupg/pinentry-auto"
  grep -qxF 'source ~/.dotfiles/.zshrc' "${home}/.zshrc" ||
    fail "zshrc source line missing"
}

test_existing_real_target_is_backed_up_before_linking() {
  local home backup
  home="$(new_home)"
  mkdir -p "${home}/.config/nvim"
  printf 'local state\n' > "${home}/.config/nvim/local.txt"

  run_install "${home}" nvim

  assert_symlink_to "${home}/.config/nvim" "${ROOT}/.config/nvim"
  backup="$(find "${home}/.config" -maxdepth 1 -type d -name 'nvim.backup.*' -print -quit)"
  [[ -n "${backup}" ]] || fail "nvim backup directory was not created"
  [[ -f "${backup}/local.txt" ]] || fail "nvim backup did not preserve local file"
}

test_zshrc_install_is_idempotent() {
  local home count
  home="$(new_home)"

  run_install "${home}" zshrc
  run_install "${home}" zshrc

  count="$(grep -c '^source ~/.dotfiles/.zshrc$' "${home}/.zshrc")"
  [[ "${count}" == "1" ]] || fail "zshrc source line count is ${count}, expected 1"
}

test_fresh_home_links_offline_modules
test_existing_real_target_is_backed_up_before_linking
test_zshrc_install_is_idempotent

printf 'ok - install smoke tests passed\n'
