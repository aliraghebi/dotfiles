#!/usr/bin/env bash

upgrade() {
  if [[ -x "$HOME/.oh-my-zsh/tools/upgrade.sh" ]]; then
    info "Upgrading oh-my-zsh"
    "$HOME/.oh-my-zsh/tools/upgrade.sh"
  fi

  local plugin plugin_dir
  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
    plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    [[ -d "$plugin_dir/.git" ]] || continue
    info "Updating $plugin"
    git -C "$plugin_dir" pull --ff-only
  done
}
