#!/usr/bin/env bash

install_brew() {
  require_brew_cask google-chrome
  require_brew defaultbrowser
}

install() {
  # macOS: handled by install_brew above
  is_macos && return 0

  if command_exists google-chrome; then
    info "google-chrome already installed"
    return 0
  fi

  info "Adding Google Chrome apt repository"
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y google-chrome-stable
  ok "google-chrome-stable installed"
}
