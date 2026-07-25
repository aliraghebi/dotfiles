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

  # The setup script drops these; they are ours to clean up
  local artifact
  for artifact in /etc/apt/sources.list.d/nodesource.list /etc/apt/keyrings/nodesource.gpg; do
    if [[ -f "$artifact" ]]; then
      pkg_record root_path "$artifact"
    fi
  done

  require_npm pnpm
}
