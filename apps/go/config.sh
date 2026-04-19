#!/usr/bin/env bash
set -euo pipefail

# Ensure go binary and installed tools are accessible in this session.
# On Linux after a fresh install, /usr/local/go/bin is not yet on PATH.
# $HOME/.local/bin (GOBIN) may not be on PATH if .zshenv hasn't been sourced.
if is_linux && [[ -x "/usr/local/go/bin/go" ]]; then
  export PATH="/usr/local/go/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

step "Configuring Go environment"

ensure_dir "$HOME/.cache/go"
ensure_dir "$HOME/.local/bin"

go env -w GOPATH="$HOME/.cache/go"
go env -w GOBIN="$HOME/.local/bin"
ok "Go environment variables configured"

step "Installing Go tools"
require_go golang.org/x/tools/gopls@latest
require_go golang.org/x/tools/cmd/goimports@latest
require_go github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
require_go github.com/go-delve/delve/cmd/dlv@latest
ok "Go tools installed"
