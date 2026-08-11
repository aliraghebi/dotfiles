#!/usr/bin/env bash

install_brew() {
  require_brew git-delta
}

install_pacman() {
  require_pacman git-delta
}

install_apt() {
  require_apt git-delta
}
