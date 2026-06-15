#!/usr/bin/env bash

set -e

DOTFILES_PATH="$(git rev-parse --show-toplevel)"
ASSUME_YES=false
BREW_UPGRADE_LABEL="com.pedh.dotfiles.brew-upgrade"
UPGRADE_FAILURES=()

INSTALL_MODULES=(brew git dircolors zshrc emacs vim nvim tmux gpg mbsync iterm2)
UTILITY_MODULES=(brew-base brew-cleanup brew-upgrade brew-upgrade-scheduled brew-schedule brew-unschedule)
MODULES=("${INSTALL_MODULES[@]}" "${UTILITY_MODULES[@]}")
MACOS_ONLY=(brew brew-base brew-cleanup brew-upgrade brew-upgrade-scheduled brew-schedule brew-unschedule iterm2)

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

homebrew_prefix() {
  if type -p brew > /dev/null; then
    brew --prefix
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' "/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' "/usr/local"
  else
    return 1
  fi
}

managed_path() {
  local prefix
  prefix="$(homebrew_prefix)" || return 1

  printf '%s\n' \
    "/usr/local/sbin:${prefix}/bin:${prefix}/sbin:${HOME}/.config/emacs/bin:${HOME}/go/bin:${HOME}/.krew/bin:${HOME}/.ghcup/bin:${prefix}/opt/rustup/bin:${HOME}/.cargo/bin:${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
}

ensure_homebrew_path() {
  local prefix
  prefix="$(homebrew_prefix)" || {
    echo "Homebrew is required." >&2
    return 1
  }

  export PATH="${prefix}/bin:${prefix}/sbin:${PATH}"
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

brewfile_entries() {
  local type="$1"

  collect_brew_bundle_files || return 1
  ruby -e '
    type = ARGV.shift
    ARGV.each do |file|
      File.readlines(file, chomp: true).each do |line|
        next unless line =~ /^\s*#{Regexp.escape(type)}\s+["'\'']([^"'\'']+)["'\'']/
        puts Regexp.last_match(1)
      end
    end
  ' "$type" "${BREW_BUNDLE_FILES[@]}"
}

preview_brewfile_entries() {
  local type="$1"
  local title="$2"
  local entries

  entries="$(brewfile_entries "$type")"
  [[ -n "$entries" ]] || return 0

  echo ""
  echo "${title}:"
  printf '%s\n' "$entries" | sed 's/^/  /'
}

preview_brewfile_entry_count() {
  local type="$1"
  local title="$2"
  local entries
  local count

  entries="$(brewfile_entries "$type")"
  [[ -n "$entries" ]] || return 0

  count="$(wc -l <<< "$entries" | tr -d '[:space:]')"
  echo ""
  printf '%s: %s entries\n' "$title" "$count"
}

preview_npm_outdated() {
  local package
  local outdated_json
  local line
  local printed=false

  type -p npm > /dev/null || return 0
  outdated_json="$(npm outdated -g --json 2>/dev/null || true)"
  [[ -n "$outdated_json" && "$outdated_json" != "{}" ]] || return 0

  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    # shellcheck disable=SC2016
    line="$(
      printf '%s\n' "$outdated_json" |
      ruby -rjson -e '
        package = ARGV.fetch(0)
        data = JSON.parse($stdin.read)
        if data.key?(package)
          info = data.fetch(package)
          puts "  #{package}: #{info["current"]} -> #{info["latest"]}"
        end
      ' "$package"
    )"
    [[ -n "$line" ]] || continue
    if [[ "$printed" != true ]]; then
      echo ""
      echo "Outdated managed npm packages:"
      printed=true
    fi
    printf '%s\n' "$line"
  done < <(brewfile_entries npm)
}

go_bin_dir() {
  local gobin
  local gopath

  gobin="$(go env GOBIN 2> /dev/null || true)"
  if [[ -n "$gobin" ]]; then
    printf '%s\n' "$gobin"
    return 0
  fi

  gopath="$(go env GOPATH 2> /dev/null || true)"
  [[ -n "$gopath" ]] || return 1
  printf '%s\n' "${gopath}/bin"
}

preview_go_outdated() {
  local tool
  local bin_dir
  local binary
  local build_info
  local package_path
  local module
  local current_version
  local update_version
  local printed=false
  local cache_key
  local cache_hit
  local i
  local -a cache_keys=()
  local -a cache_values=()

  type -p go > /dev/null || return 0
  bin_dir="$(go_bin_dir)" || return 0
  [[ -n "$bin_dir" ]] || return 0

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    binary="${bin_dir}/${tool##*/}"
    [[ -x "$binary" ]] || continue

    # shellcheck disable=SC2016
    build_info="$(
      go version -m -json "$binary" 2> /dev/null |
        ruby -rjson -e '
          data = JSON.parse($stdin.read)
          main = data.fetch("Main", {})
          puts [data["Path"], main["Path"], main["Version"]].join("\t")
        ' 2> /dev/null || true
    )"
    IFS=$'\t' read -r package_path module current_version <<< "$build_info"

    [[ "$package_path" == "$tool" ]] || continue
    [[ -n "$module" && -n "$current_version" && "$current_version" != "(devel)" ]] || continue

    cache_key="${module}@${current_version}"
    cache_hit=false
    update_version=""
    for i in "${!cache_keys[@]}"; do
      if [[ "${cache_keys[$i]}" == "$cache_key" ]]; then
        update_version="${cache_values[$i]}"
        cache_hit=true
        break
      fi
    done

    if [[ "$cache_hit" != true ]]; then
      # shellcheck disable=SC2016
      update_version="$(
        go list -m -u -json "${module}@${current_version}" 2> /dev/null |
          ruby -rjson -e '
            data = JSON.parse($stdin.read)
            update = data.dig("Update", "Version")
            puts update if update
          ' 2> /dev/null || true
      )"
      cache_keys+=("$cache_key")
      cache_values+=("$update_version")
    fi

    [[ -n "$update_version" ]] || continue

    if [[ "$printed" != true ]]; then
      echo ""
      echo "Outdated managed Go tools:"
      printed=true
    fi
    printf '  %s: %s -> %s (%s)\n' "$tool" "$current_version" "$update_version" "$module"
  done < <(brewfile_entries go)
}

preview_uv_outdated() {
  local tool
  local outdated
  local line
  local printed=false

  type -p uv > /dev/null || return 0
  outdated="$(uv tool list --outdated 2> /dev/null || true)"
  [[ -n "$outdated" ]] || return 0

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    while IFS= read -r line; do
      [[ "$line" == "$tool "* ]] || continue
      if [[ "$printed" != true ]]; then
        echo ""
        echo "Outdated managed uv tools:"
        printed=true
      fi
      printf '  %s\n' "$line"
    done <<< "$outdated"
  done < <(brewfile_entries uv)
}

preview_greedy_cask_outdated() {
  local outdated
  local cask
  local printed=false

  outdated="$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --cask --greedy 2> /dev/null || true)"
  [[ -n "$outdated" ]] || return 0

  while IFS= read -r cask; do
    [[ -n "$cask" ]] || continue
    if ! grep -qxF "$cask" <<< "$outdated"; then
      continue
    fi
    if [[ "$printed" != true ]]; then
      echo ""
      echo "Outdated auto-updating casks; not upgraded by default:"
      printed=true
    fi
    printf '  %s\n' "$cask"
  done < <(brewfile_entries cask)
}

record_upgrade_failure() {
  UPGRADE_FAILURES+=("$1")
}

install_brew_base() {
  ensure_homebrew_path

  if [[ "$ASSUME_YES" == true ]]; then
    brew bundle install --no-upgrade --file="${DOTFILES_PATH}/Brewfile"
    return
  fi

  echo "Checking base Brewfile only. Pass --yes to install."
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file="${DOTFILES_PATH}/Brewfile"
}

install_brew() {
  ensure_homebrew_path

  if [[ "$ASSUME_YES" == true ]]; then
    brew_bundle_with_profiles install --no-upgrade
    return
  fi

  echo "Checking Brewfile profiles only. Pass --yes to install."
  HOMEBREW_NO_AUTO_UPDATE=1 brew_bundle_check_with_profiles
}

install_brew_cleanup() {
  ensure_homebrew_path

  if [[ "$ASSUME_YES" == true ]]; then
    brew_bundle_with_profiles cleanup --all --force
    return
  fi

  if ! HOMEBREW_NO_AUTO_UPDATE=1 brew_bundle_with_profiles cleanup --all; then
    echo "Review the cleanup preview above."
    echo "Run ./install.sh brew-cleanup --yes to apply it."
  fi
}

upgrade_go_tools() {
  local tool

  type -p go > /dev/null || return 0
  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    echo "Upgrading Go tool: $tool"
    go install "${tool}@latest"
  done < <(brewfile_entries go)
}

upgrade_npm_packages() {
  local package

  type -p npm > /dev/null || return 0
  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    echo "Upgrading npm package: $package"
    npm install -g "${package}@latest"
  done < <(brewfile_entries npm)
}

upgrade_krew_plugins() {
  local plugin
  local output
  local status

  type -p kubectl > /dev/null || return 0
  kubectl krew version > /dev/null 2>&1 || return 0

  kubectl krew update
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] || continue
    echo "Upgrading krew plugin: $plugin"
    status=0
    output="$(kubectl krew upgrade --no-update-index "$plugin" 2>&1)" || status=$?
    if [[ $status -ne 0 ]]; then
      printf '%s\n' "$output"
      [[ "$output" == *"newest version is already installed"* ]] && continue
      echo "Retrying krew plugin: $plugin"
      status=0
      output="$(kubectl krew upgrade --no-update-index "$plugin" 2>&1)" || status=$?
      printf '%s\n' "$output"
      if [[ $status -ne 0 ]]; then
        record_upgrade_failure "krew plugin $plugin"
        continue
      fi
      continue
    fi
    printf '%s\n' "$output"
  done < <(brewfile_entries krew)
}

upgrade_uv_tools() {
  local tool

  type -p uv > /dev/null || return 0
  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    echo "Upgrading uv tool: $tool"
    uv tool upgrade "$tool"
  done < <(brewfile_entries uv)
}

vscode_extension_installed() {
  local vscode_cmd="$1"
  local extension="$2"

  "$vscode_cmd" --list-extensions 2> /dev/null |
    awk -v extension="$extension" 'tolower($0) == tolower(extension) { found = 1 } END { exit !found }'
}

upgrade_vscode_extensions() {
  local extension
  local vscode_cmd=""
  local output
  local status

  if type -p cursor > /dev/null; then
    vscode_cmd="$(type -p cursor)"
  elif type -p code > /dev/null; then
    vscode_cmd="$(type -p code)"
  else
    return 0
  fi

  while IFS= read -r extension; do
    [[ -n "$extension" ]] || continue
    echo "Upgrading VSCode extension: $extension"
    status=0
    output="$("$vscode_cmd" --install-extension "$extension" --force 2>&1)" || status=$?
    printf '%s\n' "$output"
    if [[ $status -ne 0 ]]; then
      if [[ "$output" == *"not found"* ]] && vscode_extension_installed "$vscode_cmd" "$extension"; then
        echo "Skipping unavailable installed VSCode extension: $extension"
        continue
      fi
      record_upgrade_failure "VSCode extension $extension"
    fi
  done < <(brewfile_entries vscode)
}

install_brew_upgrade() {
  local path_value

  ensure_homebrew_path

  if [[ "$ASSUME_YES" != true ]]; then
    echo "Checking Brewfile upgrade status. Pass --yes to upgrade."
    HOMEBREW_NO_AUTO_UPDATE=1 brew_bundle_with_profiles check --verbose || true
    preview_go_outdated
    preview_npm_outdated
    preview_uv_outdated
    preview_greedy_cask_outdated
    preview_brewfile_entry_count krew "Managed Krew plugins; no official dry-run/outdated check; --yes runs krew update/upgrade"
    preview_brewfile_entry_count vscode "Managed VSCode/Cursor extensions; no official outdated check; --yes reinstalls each with --force"
    return 0
  fi

  path_value="$(managed_path)" || return 1
  UPGRADE_FAILURES=()
  export PATH="${path_value}:${PATH}"
  brew update
  brew_bundle_with_profiles install --upgrade
  upgrade_go_tools
  upgrade_npm_packages
  upgrade_krew_plugins
  upgrade_uv_tools
  upgrade_vscode_extensions

  if [[ ${#UPGRADE_FAILURES[@]} -gt 0 ]]; then
    echo ""
    echo "Upgrade completed with failures:"
    printf '  %s\n' "${UPGRADE_FAILURES[@]}"
    return 1
  fi
}

install_brew_upgrade_scheduled() {
  local status=0

  ASSUME_YES=true
  if ! brew_upgrade_on_ac_power; then
    echo "Skipping scheduled brew-upgrade: device is not on AC power."
    notify_brew_upgrade "Skipped because device is not on AC power"
    return 0
  fi

  if configure_brew_upgrade_sudo_askpass; then
    install_brew_upgrade || status=$?
  else
    status=$?
  fi

  if [[ $status -eq 0 ]]; then
    notify_brew_upgrade "Completed successfully"
  else
    notify_brew_upgrade "Failed with exit code ${status}"
  fi

  return "$status"
}

brew_upgrade_on_ac_power() {
  local power_status

  power_status="$(pmset -g ps 2> /dev/null)" || {
    echo "Warning: unable to determine power source; proceeding with scheduled brew-upgrade." >&2
    return 0
  }

  [[ "$power_status" == *"'AC Power'"* ]]
}

notify_brew_upgrade() {
  local message="$1"
  local notifier=""

  if type -p terminal-notifier > /dev/null; then
    notifier="$(type -p terminal-notifier)"
    "$notifier" -title "dotfiles brew-upgrade" -message "$message"
  fi
}

brew_upgrade_plist() {
  printf '%s\n' "${HOME}/Library/LaunchAgents/${BREW_UPGRADE_LABEL}.plist"
}

brew_upgrade_log_dir() {
  printf '%s\n' "${HOME}/Library/Logs/dotfiles"
}

brew_upgrade_support_dir() {
  printf '%s\n' "${HOME}/Library/Application Support/dotfiles"
}

brew_upgrade_sudo_askpass() {
  printf '%s\n' "$(brew_upgrade_support_dir)/brew-upgrade-sudo-askpass"
}

install_brew_upgrade_sudo_askpass() {
  local helper
  local prefix

  prefix="$(homebrew_prefix)" || return 1
  if ! type -p pinentry-mac > /dev/null; then
    echo "pinentry-mac is required for scheduled brew-upgrade sudo prompts." >&2
    echo "Install it with: brew install pinentry-mac" >&2
    return 1
  fi

  helper="$(brew_upgrade_sudo_askpass)"
  mkdir -p "$(dirname "$helper")"
  cat > "$helper" <<EOF
#!/bin/sh
PATH='${prefix}/bin:/usr/bin:/bin'
printf "%s\n" "OPTION allow-external-cache" "SETOK OK" "SETCANCEL Cancel" "SETDESC dotfiles brew-upgrade needs your admin password to complete cask upgrades" "SETPROMPT Enter Password:" "SETTITLE dotfiles brew-upgrade Password Request" "GETPIN" | pinentry-mac --no-global-grab --timeout 60 | /usr/bin/awk '/^D / {print substr(\$0, index(\$0, \$2))}'
EOF
  chmod 0555 "$helper"
  printf '%s\n' "$helper"
}

configure_brew_upgrade_sudo_askpass() {
  local helper

  helper="$(install_brew_upgrade_sudo_askpass)" || return 1
  export SUDO_ASKPASS="$helper"
  echo "Configured SUDO_ASKPASS for scheduled brew-upgrade; sudo will prompt only if needed."
}

install_brew_schedule() {
  local plist
  local log_dir
  local path_value

  plist="$(brew_upgrade_plist)"
  log_dir="$(brew_upgrade_log_dir)"
  path_value="$(managed_path)" || return 1

  if [[ "$ASSUME_YES" != true ]]; then
    echo "Brew upgrade schedule target:"
    echo "  Plist: $plist"
    echo "  Command: ${DOTFILES_PATH}/install.sh brew-upgrade-scheduled"
    echo "  Schedule: Sunday 10:00"
    echo "  Sudo: pinentry-mac GUI prompt only when sudo is needed"
    echo "Pass --yes to install or refresh the LaunchAgent."
    return 0
  fi

  mkdir -p "$(dirname "$plist")" "$log_dir"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${BREW_UPGRADE_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>-i</string>
    <string>HOME=${HOME}</string>
    <string>PATH=${path_value}</string>
    <string>LANG=${LANG:-en_US.UTF-8}</string>
    <string>HOMEBREW_NO_ENV_HINTS=1</string>
    <string>/bin/bash</string>
    <string>${DOTFILES_PATH}/install.sh</string>
    <string>brew-upgrade-scheduled</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${DOTFILES_PATH}</string>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>0</integer>
    <key>Hour</key>
    <integer>10</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>${log_dir}/brew-upgrade.log</string>
  <key>StandardErrorPath</key>
  <string>${log_dir}/brew-upgrade.log</string>
</dict>
</plist>
EOF

  /bin/launchctl bootout "gui/${UID}" "$plist" > /dev/null 2>&1 || true
  env -i HOME="${HOME}" PATH="/usr/bin:/bin:/usr/sbin:/sbin" LANG="${LANG:-en_US.UTF-8}" \
    /bin/launchctl bootstrap "gui/${UID}" "$plist"
}

install_brew_unschedule() {
  local plist

  plist="$(brew_upgrade_plist)"

  if [[ "$ASSUME_YES" != true ]]; then
    echo "Brew upgrade schedule plist:"
    echo "  $plist"
    if [[ -f "$plist" ]]; then
      launchctl print "gui/${UID}/${BREW_UPGRADE_LABEL}" > /dev/null 2>&1 &&
        echo "Status: loaded" ||
        echo "Status: plist exists but is not loaded"
    else
      echo "Status: not installed"
    fi
    echo "Pass --yes to unload and remove it."
    return 0
  fi

  launchctl bootout "gui/${UID}" "$plist" > /dev/null 2>&1 || true
  rm -f "$plist"
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
