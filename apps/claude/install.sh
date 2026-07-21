#!/usr/bin/env bash
set -euo pipefail

install_brew() {
  if [[ -d "/Applications/Claude.app" ]]; then
    info "Claude desktop app already present, skipping"
    return 0
  fi
  require_brew_cask claude
}

install() {
  if command_exists claude; then
    info "Claude Code already installed"
    return 0
  fi
  require_script "https://claude.ai/install.sh" bash
}
