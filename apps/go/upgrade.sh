#!/usr/bin/env bash

upgrade() {
  is_macos && return 0

  local go_bin
  go_bin=$(command -v go 2>/dev/null || true)
  [[ -z "$go_bin" && -x "/usr/local/go/bin/go" ]] && go_bin="/usr/local/go/bin/go"
  if [[ -z "$go_bin" ]]; then
    info "go not installed — run: dotfiles install go"
    return 0
  fi

  local latest current
  latest=$(_go_latest_version)
  current=$("$go_bin" version | awk '{print $3}')
  if [[ "$current" == "$latest" ]]; then
    info "go already at $latest"
    return 0
  fi

  info "Upgrading go: $current → $latest"
  _go_install_linux "$latest"
}
