#!/usr/bin/env bash
set -euo pipefail

# RTK.md is generated globally by rtk, not linked from this repo.
if command_exists rtk; then
  info "Generating global RTK.md via rtk init"
  rtk init -g
  ok "RTK.md generated"
else
  warn "rtk not found, skipping RTK.md generation"
fi
