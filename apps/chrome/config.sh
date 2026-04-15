#!/usr/bin/env bash

# Configure gopass-jsonapi native messaging host for Chrome
if command_exists gopass-jsonapi; then
  info "Configuring gopass-jsonapi native messaging host for Chrome"
  gopass-jsonapi configure --browser chrome
  ok "gopass-jsonapi configured for Chrome"
else
  warn "gopass-jsonapi not found, skipping native messaging host setup"
fi

# Set Chrome as default browser
if is_macos; then
  if command_exists defaultbrowser; then
    info "Setting Chrome as default browser"
    defaultbrowser chrome
    ok "Chrome set as default browser"
  else
    warn "defaultbrowser not found, skipping default browser setup"
  fi
else
  if command_exists xdg-settings; then
    info "Setting Chrome as default browser"
    xdg-settings set default-web-browser google-chrome.desktop
    ok "Chrome set as default browser"
  else
    warn "xdg-settings not found, skipping default browser setup"
  fi
fi
