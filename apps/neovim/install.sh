#!/usr/bin/env bash

install_brew() {
  require_brew neovim
}

install_pacman() {
  require_pacman neovim
}

install_apt() {
  require_apt neovim
}