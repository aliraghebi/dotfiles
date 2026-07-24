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
  if ! command_exists starship; then
    require_script "https://starship.rs/install.sh" sh -s -- --yes
  fi
}
