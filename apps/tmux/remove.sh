#!/usr/bin/env bash
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  info "Removing tpm"
  rm -rf "$HOME/.tmux/plugins/tpm"
  ok "tpm removed"
fi
