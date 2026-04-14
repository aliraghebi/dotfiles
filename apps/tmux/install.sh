#!/usr/bin/env bash

install_brew() {
  require_brew tmux
}

install_pacman() {
  require_pacman tmux
}

install_apt() {
  require_apt tmux
}
