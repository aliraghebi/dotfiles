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
  if ! command -v starship >/dev/null 2>&1; then
    info "Installing starship via install script..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi
}
