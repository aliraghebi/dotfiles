#!/usr/bin/env bash
set -euo pipefail

install_brew() {
  # Never let brew adopt a desktop app that was installed from the website —
  # but once brew owns the cask, it must stay in the install/upgrade path.
  if [[ -d "/Applications/Claude.app" ]] && ! brew_cask_installed claude; then
    info "Claude desktop app present but not brew-managed — it updates itself in-app"
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
