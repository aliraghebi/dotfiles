#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/os.sh"
source "$DOTFILES_DIR/lib/pkg.sh"
source "$TESTS_DIR/unit.sh"

# ── require_brew idempotency ──

test_require_brew_skips_when_already_installed() {
  # Stub brew to report the package as already installed
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    echo "FAIL: brew install should not have been called" >&2
    return 1
  }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
}

test_require_brew_installs_when_missing() {
  local installed=false
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    if [[ "$1" == "install" ]]; then installed=true; return 0; fi
  }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
  assert_equals "true" "$installed"
}

# ── require_brew_cask idempotency ──

test_require_brew_cask_skips_when_already_installed() {
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    echo "FAIL: brew install should not have been called" >&2
    return 1
  }
  export -f brew
  require_brew_cask "some-cask"
  unset -f brew
}

test_require_brew_cask_installs_when_missing() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/installed"
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    if [[ "$1" == "install" ]]; then touch "$marker"; return 0; fi
  }
  export -f brew
  require_brew_cask "some-cask"
  unset -f brew
  assert_file_exists "$marker"
}

# ── require_apt idempotency ──

test_require_apt_skips_when_already_installed() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  dpkg() {
    if [[ "$1" == "-s" ]]; then return 0; fi
  }
  export -f dpkg
  require_apt "some-pkg"
  unset -f dpkg
}


test_require_apt_installs_when_missing() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  local installed=false
  dpkg() { return 1; }
  sudo() {
    shift  # drop "sudo"
    local cmd="$1"; shift
    if [[ "$cmd" == "apt-get" ]]; then installed=true; return 0; fi
  }
  export -f dpkg sudo
  require_apt "some-pkg"
  unset -f dpkg sudo
  assert_equals "true" "$installed"
}

# ── require_cargo idempotency ──

test_require_cargo_skips_when_binary_exists() {
  command_exists() { return 0; }
  export -f command_exists
  local installed=false
  cargo() { installed=true; }
  export -f cargo
  require_cargo "ripgrep"
  unset -f command_exists cargo
  assert_equals "false" "$installed"
}

test_require_cargo_installs_when_missing() {
  command_exists() { return 1; }
  export -f command_exists
  local installed=false
  cargo() { installed=true; }
  export -f cargo
  require_cargo "ripgrep"
  unset -f command_exists cargo
  assert_equals "true" "$installed"
}

# ── require_script ──

test_require_script_uses_sh_by_default() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/ran"
  curl() { echo "touch \"$marker\""; }
  export -f curl
  require_script "https://example.com/install.sh"
  unset -f curl
  assert_file_exists "$marker"
}

test_require_script_uses_custom_interpreter() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/ran"
  curl() { echo "touch \"$marker\""; }
  export -f curl
  require_script "https://example.com/install.sh" /bin/bash
  unset -f curl
  assert_file_exists "$marker"
}

run_tests
