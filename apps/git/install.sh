#!/usr/bin/env bash

install_brew() {
  require_brew git-filter-repo
}

install_pacman() {
  require_pacman git-filter-repo
}

install_apt() {
  require_apt git-filter-repo
}
