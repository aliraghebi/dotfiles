#!/usr/bin/env bash

install_brew() {
  require_brew starship
}

install_pacman() {
  require_pacman starship
}

install() {
  # On macOS brew handles it; on Linux use the official installer
  is_macos && return 0

  # The installer drops a single binary here
  local bin="/usr/local/bin/starship"
  local owned=false
  if ! command_exists starship; then
    require_script "https://starship.rs/install.sh" sh -s -- --yes
    owned=true
  fi
  if [[ -e "$bin" ]]; then
    pkg_record root_path "$bin" "$owned"
  fi
}
