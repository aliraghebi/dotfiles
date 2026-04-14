#!/usr/bin/env bash
# lib/log.sh — logging helpers

# Detect non-TTY: suppress colors when output is piped
if [[ -t 1 ]]; then
  _CYAN='\033[0;36m'
  _GREEN='\033[0;32m'
  _YELLOW='\033[0;33m'
  _RED='\033[0;31m'
  _BOLD='\033[1m'
  _RESET='\033[0m'
else
  _CYAN=''
  _GREEN=''
  _YELLOW=''
  _RED=''
  _BOLD=''
  _RESET=''
fi

info() {
  printf "${_CYAN}  → %s${_RESET}\n" "$*"
}

ok() {
  printf "${_GREEN}  ✓ %s${_RESET}\n" "$*"
}

warn() {
  printf "${_YELLOW}  ! %s${_RESET}\n" "$*"
}

error() {
  printf "${_RED}  ✗ %s${_RESET}\n" "$*" >&2
}

step() {
  printf "${_BOLD}\n[ %s ]${_RESET}\n" "$*"
}
