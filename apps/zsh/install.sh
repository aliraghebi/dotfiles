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

# _zsh_require_plugin <name> <repo-url> — clone into ZSH_CUSTOM, record the dir
_zsh_require_plugin() {
  local name="$1"
  local url="$2"
  local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${name}"

  if [[ ! -d "$dir" ]]; then
    info "Installing $name"
    git clone "$url" "$dir"
    pkg_record path "$dir"
  else
    info "$name already installed"
    pkg_record path "$dir" false
  fi
}

install() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing oh-my-zsh"
    RUNZSH=no CHSH=no require_script "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    pkg_record path "$HOME/.oh-my-zsh"
  else
    info "oh-my-zsh already installed"
    pkg_record path "$HOME/.oh-my-zsh" false
  fi

  _zsh_require_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
  _zsh_require_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
  _zsh_require_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

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
