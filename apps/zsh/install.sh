#!/usr/bin/env bash

install_brew() {
  require_brew zsh
}

install_pacman() {
  require_pacman zsh
}

install_apt() {
  require_apt zsh
}

install() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing oh-my-zsh"
    RUNZSH=no CHSH=no require_script "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  else
    info "oh-my-zsh already installed"
  fi

  local zsh_path
  zsh_path=$(command -v zsh 2>/dev/null || true)
  if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
    info "Setting default shell to zsh"
    chsh -s "$zsh_path"
  fi
}
