#!/usr/bin/env bash

install_brew() {
  require_brew_cask docker
}

install_pacman() {
  require_pacman docker
}

install() {
  is_macos && return 0

  local owned=true
  if command -v docker >/dev/null 2>&1; then
    info "Docker already installed"
    owned=false
  else
    info "Installing Docker Engine via official script"
    curl -fsSL https://get.docker.com | sh
  fi

  # get.docker.com installs these through apt but tells us nothing, so name the
  # packages here. Images and volumes under /var/lib/docker are data and stay,
  # as does the docker group and its members.
  local pkg
  for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      pkg_record apt "$pkg" "$owned"
    fi
  done

  if [[ "$owned" == false ]]; then
    return 0
  fi

  if getent group docker >/dev/null 2>&1; then
    info "Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
    info "Log out and back in for group membership to take effect"
  fi
}
