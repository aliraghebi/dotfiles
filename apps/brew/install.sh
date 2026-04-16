#!/usr/bin/env bash

install() {
  if command_exists brew; then
    info "Homebrew already installed"
    return 0
  fi

  if ! xcode-select -p >/dev/null 2>&1; then
    step "Installing Xcode Command Line Tools"
    xcode-select --install 2>/dev/null || true
    info "Click 'Install' in the dialog — waiting for completion..."
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
    ok "Xcode Command Line Tools installed"
  fi

  step "Installing Homebrew"
  require_script "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" /bin/bash

  # Make brew available in the current session (ARM: /opt/homebrew, Intel: /usr/local)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}
