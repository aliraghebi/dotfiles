#!/usr/bin/env bash

install_brew() {
  require_brew derailed/k9s/k9s
}

install_pacman() {
  require_pacman k9s
}