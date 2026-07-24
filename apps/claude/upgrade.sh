#!/usr/bin/env bash

upgrade() {
  if ! command_exists claude; then
    info "Claude Code not installed — run: dotfiles install claude"
    return 0
  fi
  info "Upgrading Claude Code"
  claude update
}
