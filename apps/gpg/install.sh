#!/usr/bin/env bash

install_brew() {
  require_brew gnupg
}

install_apt() {
  require_apt gpg
}

install_pacman() {
  require_pacman gnupg
}
