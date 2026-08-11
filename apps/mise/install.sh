#!/usr/bin/env bash

install_brew() {
  require_brew mise
}

install_pacman() {
  require_pacman mise
}

install() {
  # brew and pacman handle those systems; everything else uses the official
  # installer, which drops a single binary here.
  is_macos && return 0

  local bin="$HOME/.local/bin/mise"
  local owned=false
  if ! command_exists mise; then
    require_script "https://mise.run"
    owned=true
  fi
  if [[ -e "$bin" ]]; then
    pkg_record path "$bin" "$owned"
  fi
}
