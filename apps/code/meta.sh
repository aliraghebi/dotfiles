#!/usr/bin/env bash
APP_OS="macos"
APP_BINARY="code"
APP_DESCRIPTION="Visual Studio Code"
APP_CONFIGS=(
  "config/settings.json : ~/Library/Application Support/Code/User/settings.json : macos"
  "config/settings.json : ~/.config/Code/User/settings.json : linux"
)
