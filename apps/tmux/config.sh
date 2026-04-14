#!/usr/bin/env bash
# Install Tmux Plugin Manager (tpm)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  info "Installing tpm (Tmux Plugin Manager)"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "tpm installed"
else
  info "tpm already installed"
fi
