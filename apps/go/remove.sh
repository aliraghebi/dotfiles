#!/usr/bin/env bash
set -euo pipefail

if is_linux && [[ -x "/usr/local/go/bin/go" ]]; then
  export PATH="/usr/local/go/bin:$PATH"
fi

if command_exists go; then
  step "Restoring Go environment defaults"
  go env -u GOPATH
  go env -u GOBIN
  ok "Go environment variables unset"
else
  warn "go not found — skipping go env cleanup"
fi
