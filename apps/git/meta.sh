#!/usr/bin/env bash
APP_OS="macos,linux"
APP_BINARY="git"
APP_DESCRIPTION="Git version control"
# Preferred pager; core.pager falls back to $PAGER when it is absent.
APP_DEPS=("delta")
APP_CONFIGS=(
  "config/config : ~/.config/git/config"
  "config/ignore : ~/.config/git/ignore"
)
