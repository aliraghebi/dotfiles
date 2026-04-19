#!/usr/bin/env bash
set -euo pipefail

install_brew() {
  require_brew go
}

install() {
  is_macos && return 0
  command_exists go || [[ -x "/usr/local/go/bin/go" ]] && { info "go already installed"; return 0; }

  local version arch
  version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
  arch=$(cpu_arch)

  if [[ "$arch" != "amd64" && "$arch" != "arm64" ]]; then
    error "Unsupported architecture for Go install: $arch"
    return 1
  fi

  local archive="${version}.linux-${arch}.tar.gz"
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  info "Downloading ${version} (linux/${arch})"
  download_file "https://go.dev/dl/${archive}" "${tmp}/${archive}"

  info "Installing Go to /usr/local/go"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "${tmp}/${archive}"

  ok "${version} installed"
}
