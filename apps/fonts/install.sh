#!/usr/bin/env bash

_install_nerd_font() {
  local font_name="$1"
  local zip_name="$2"
  local font_dir="${HOME}/.local/share/fonts/${font_name}"

  if [[ -d "$font_dir" ]] && [[ -n "$(ls -A "$font_dir" 2>/dev/null)" ]]; then
    info "${font_name} nerd font already installed"
    return 0
  fi

  info "Fetching latest nerd-fonts release version"
  local version
  version=$(curl -fsSL "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4)
  if [[ -z "$version" ]]; then
    warn "Could not fetch nerd-fonts version — skipping ${font_name}"
    return 1
  fi

  local temp_dir
  temp_dir=$(mktemp -d)
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_name}"

  info "Downloading ${font_name} nerd font ${version}"
  if ! download_file "$url" "${temp_dir}/font.zip"; then
    warn "Failed to download ${font_name}"
    rm -rf "$temp_dir"
    return 1
  fi

  ensure_dir "$font_dir"
  unzip -qo "${temp_dir}/font.zip" -d "$font_dir"
  rm -rf "$temp_dir"
  ok "Installed ${font_name} nerd font ${version}"
}

install_brew() {
  require_brew_cask font-jetbrains-mono
  require_brew_cask font-jetbrains-mono-nerd-font
  require_brew_cask font-fira-code
  require_brew_cask font-fira-code-nerd-font
  require_brew_cask font-vazirmatn
  require_brew_cask font-dejavu
  require_brew_cask font-roboto
}

install_pacman() {
  require_pacman ttf-jetbrains-mono
  require_pacman ttf-jetbrains-mono-nerd
  require_pacman ttf-firacode-nerd
  require_pacman ttf-dejavu
  require_pacman ttf-roboto
  require_pacman noto-fonts
  require_pacman noto-fonts-emoji
}

install_apt() {
  require_apt unzip
  require_apt fonts-jetbrains-mono
  require_apt fonts-firacode
  require_apt fonts-dejavu
  require_apt fonts-roboto
  require_apt fonts-noto
  require_apt fonts-noto-color-emoji

  _install_nerd_font "JetBrainsMono" "JetBrainsMono.zip"
  _install_nerd_font "FiraCode" "FiraCode.zip"

  fc-cache -f
  ok "Font cache rebuilt"
}