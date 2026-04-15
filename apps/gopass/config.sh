#!/usr/bin/env bash
# GOPASS_REPO is set in meta.sh

if gopass ls >/dev/null 2>&1; then
  info "Password store already initialized"
else
  step "Cloning password store"
  gopass clone --check-keys=false "${GOPASS_REPO}"
  ok "Password store cloned"
fi
