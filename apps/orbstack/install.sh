#!/usr/bin/env bash

install_brew() {
  require_brew_cask orbstack

  # Both products manage /var/run/docker.sock; whichever starts last wins.
  if brew_cask_installed docker; then
    warn "Docker Desktop is also installed — quit it before using OrbStack"
  fi
}
