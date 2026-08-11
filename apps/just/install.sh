#!/usr/bin/env bash

install_brew() {
  require_brew just
}

install_pacman() {
  require_pacman just
}

install() {
  # brew and pacman handle those systems; everything else uses the official
  # installer, which drops a single binary wherever --to points.
  is_macos && return 0

  local bin="$HOME/.local/bin/just"
  local owned=false
  if ! command_exists just; then
    ensure_dir "$HOME/.local/bin"
    require_script "https://just.systems/install.sh" bash -s -- --to "$HOME/.local/bin"
    owned=true
  fi
  if [[ -e "$bin" ]]; then
    pkg_record path "$bin" "$owned"
  fi
}
