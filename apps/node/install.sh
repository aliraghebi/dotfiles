#!/usr/bin/env bash
set -euo pipefail

install_brew() {
  require_brew node
  require_brew pnpm
}

install() {
  is_macos && return 0

  if ! command_exists node; then
    info "Setting up NodeSource LTS repository"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    require_apt nodejs
  else
    info "node already installed"
  fi

  if command_exists pnpm; then
    info "pnpm already installed"
    return 0
  fi

  info "Installing pnpm via npm"
  npm install -g pnpm
  ok "pnpm installed"
}
