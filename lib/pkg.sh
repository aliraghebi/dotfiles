#!/usr/bin/env bash
# lib/pkg.sh — idempotent package install helpers

require_brew() {
  local pkg="$1"
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    info "$pkg already installed via brew"
    return 0
  fi
  info "Installing $pkg via brew"
  brew install "$pkg"
}

require_brew_cask() {
  local pkg="$1"
  if brew list --cask "$pkg" >/dev/null 2>&1; then
    info "$pkg already installed via brew cask"
    return 0
  fi
  info "Installing $pkg via brew cask"
  local output
  if ! output=$(brew install --cask "$pkg" 2>&1); then
    if echo "$output" | grep -q "there is already"; then
      warn "$pkg: files already exist on disk, skipping"
      return 0
    fi
    echo "$output" >&2
    return 1
  fi
  echo "$output"
}

require_brew_tap() {
  local tap="$1"
  local pkg="$2"
  if ! brew tap | grep -q "^${tap}$" 2>/dev/null; then
    info "Tapping $tap"
    brew tap "$tap"
  fi
  require_brew "$pkg"
}

require_apt() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    info "$pkg already installed via apt"
    return 0
  fi
  info "Installing $pkg via apt"
  sudo apt-get install -y "$pkg"
}

require_cargo() {
  local crate="$1"
  if command_exists "$crate"; then
    info "$crate already installed via cargo"
    return 0
  fi
  info "Installing $crate via cargo"
  cargo install "$crate"
}

require_go() {
  local module="$1"
  local bin
  bin=$(basename "$module" | cut -d@ -f1)
  if command_exists "$bin"; then
    info "$bin already installed via go"
    return 0
  fi
  info "Installing $module via go"
  go install "$module"
}

require_pip() {
  local pkg="$1"
  if pip3 show "$pkg" >/dev/null 2>&1; then
    info "$pkg already installed via pip"
    return 0
  fi
  info "Installing $pkg via pip"
  pip3 install --user "$pkg"
}

require_pacman() {
  local pkg="$1"
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    info "$pkg already installed via pacman"
    return 0
  fi
  info "Installing $pkg via pacman"
  sudo pacman -S --noconfirm "$pkg"
}

# require_gh_release <owner/repo> <binary> [asset_template]
# Without asset_template: auto-detects asset by OS name, installs binary to ~/.local/bin.
# With asset_template: evaluates the template with $version set from the latest release tag,
#   installs .deb via dpkg or drops a plain binary into ~/.local/bin.
# Examples:
#   require_gh_release "cli/cli" "gh"
#   require_gh_release "gopasspw/gopass" "gopass" 'gopass_${version#v}_linux_amd64.deb'
require_gh_release() {
  local repo="$1"
  local binary="$2"
  local asset_tpl="${3:-}"

  if command_exists "$binary"; then
    info "$binary already installed"
    return 0
  fi

  info "Installing $binary from $repo latest release"

  local version asset url tmp
  version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r '.tag_name')

  if [[ -z "$version" ]]; then
    error "Could not determine latest $binary version"
    return 1
  fi

  if [[ -n "$asset_tpl" ]]; then
    asset=$(eval echo "$asset_tpl")
    url="https://github.com/${repo}/releases/download/${version}/${asset}"
  else
    url=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
      | jq -r ".assets[] | select(.name | contains(\"$(uname -s | tr '[:upper:]' '[:lower:]')\")) | .browser_download_url" \
      | head -1)
    asset=$(basename "$url")
  fi

  if [[ -z "$url" ]]; then
    error "Could not find release asset for $repo"
    return 1
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  info "Downloading ${asset}"
  curl -fsSL -o "${tmp}/${asset}" "${url}"

  if [[ "$asset" == *.deb ]]; then
    sudo dpkg -i "${tmp}/${asset}"
  else
    ensure_dir "$HOME/.local/bin"
    mv "${tmp}/${asset}" "$HOME/.local/bin/$binary"
    chmod +x "$HOME/.local/bin/$binary"
  fi

  ok "$binary installed"
}

require_script() {
  local url="$1"
  info "Running install script from $url"
  curl -fsSL "$url" | sh
}
