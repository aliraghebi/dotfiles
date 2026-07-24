#!/usr/bin/env bash

upgrade() {
  if ! command_exists brew; then
    info "Homebrew not installed — run: dotfiles install brew"
    return 0
  fi
  info "Updating Homebrew"
  brew update
}
