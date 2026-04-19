#!/usr/bin/env bash
# lib/os.sh — OS detection helpers

is_macos() {
  [[ "$(uname -s)" == Darwin ]]
}

is_linux() {
  [[ "$(uname -s)" == Linux ]]
}

os_name() {
  if is_macos; then
    echo "macos"
  else
    echo "linux"
  fi
}

linux_distro() {
  if [[ -f /etc/os-release ]]; then
    local id
    id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    echo "$id"
  else
    echo "unknown"
  fi
}

is_brew() {
  command_exists brew
}

is_apt() {
  command_exists apt-get
}

is_pacman() {
  command_exists pacman
}

cpu_arch() {
  case "$(uname -m)" in
    x86_64)        echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)             uname -m ;;
  esac
}

dotfiles_state_file() {
  if is_macos; then
    echo "$HOME/Library/Application Support/dotfiles/state.json"
  else
    echo "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.json"
  fi
}
