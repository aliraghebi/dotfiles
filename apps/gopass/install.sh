#!/usr/bin/env bash

install_brew() {
  require_brew gopass
}

install() {
  # macOS: handled by install_brew above
  is_macos && return 0

  if command_exists gopass; then
    info "gopass already installed"
    return 0
  fi

  info "Installing gopass from GitHub releases"
  local version
  version=$(curl -fsSL "https://api.github.com/repos/gopasspw/gopass/releases/latest" \
    | jq -r '.tag_name' | sed 's/^v//')

  if [[ -z "$version" ]]; then
    error "Could not determine latest gopass version"
    return 1
  fi

  local deb="gopass_${version}_linux_amd64.deb"
  local url="https://github.com/gopasspw/gopass/releases/download/v${version}/${deb}"
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  info "Downloading ${deb}"
  curl -fsSL -o "${tmp}/${deb}" "${url}"
  sudo dpkg -i "${tmp}/${deb}"
  ok "gopass ${version} installed"
}
