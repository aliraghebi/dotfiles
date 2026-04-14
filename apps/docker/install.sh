#!/usr/bin/env bash

install_brew() {
  require_brew_cask docker
}

install_pacman() {
  require_pacman docker
}

install() {
  is_macos && return 0

  if command -v docker >/dev/null 2>&1; then
    info "Docker already installed"
    return 0
  fi

  info "Installing Docker Engine via official script"
  curl -fsSL https://get.docker.com | sh

  if getent group docker >/dev/null 2>&1; then
    info "Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
    info "Log out and back in for group membership to take effect"
  fi
}
