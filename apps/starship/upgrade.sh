#!/usr/bin/env bash

upgrade() {
  is_macos && return 0
  if ! command_exists starship; then
    info "starship not installed — run: dotfiles install starship"
    return 0
  fi
  # The official installer overwrites the existing binary with the latest release
  require_script "https://starship.rs/install.sh" sh -s -- --yes
}
