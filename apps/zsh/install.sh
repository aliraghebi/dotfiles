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

  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [[ ! -d "$plugin_dir" ]]; then
    info "Installing zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
  else
    info "zsh-autosuggestions already installed"
  fi

  local syntax_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [[ ! -d "$syntax_dir" ]]; then
    info "Installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$syntax_dir"
  else
    info "zsh-syntax-highlighting already installed"
  fi

  local history_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"
  if [[ ! -d "$history_dir" ]]; then
    info "Installing zsh-history-substring-search"
    git clone https://github.com/zsh-users/zsh-history-substring-search "$history_dir"
  else
    info "zsh-history-substring-search already installed"
  fi

  local zsh_path
  zsh_path=$(command -v zsh 2>/dev/null || true)
  if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
    if ! grep -qF "$zsh_path" /etc/shells; then
      info "Adding $zsh_path to /etc/shells"
      echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    info "Setting default shell to zsh"
    chsh -s "$zsh_path"
  fi
}
