#!/usr/bin/env bash
APP_OS="macos"
APP_BINARY="neovide"
APP_DESCRIPTION="GPU-accelerated GUI frontend for Neovim"
APP_DEPS=("neovim")
APP_CONFIGS=(
  "config/neovide : ~/.config/neovide"
)
