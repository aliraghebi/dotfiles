#!/usr/bin/env bash

install_brew() {
  require_brew xh
}

install_pacman() {
  require_pacman xh
}

install() {
  # xh's own installer prompts for an install directory, so it cannot run
  # unattended through require_script — build from source instead.
  is_macos && return 0
  command_exists pacman && return 0

  require_cargo xh
}
