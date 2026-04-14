#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/os.sh"
source "$TESTS_DIR/unit.sh"

# ── is_macos / is_linux ──

test_os_detection_is_consistent() {
  # Exactly one of is_macos or is_linux should be true
  local mac=0 linux=0
  is_macos && mac=1 || true
  is_linux && linux=1 || true
  local sum=$((mac + linux))
  assert_equals "1" "$sum"
}

# ── os_name ──

test_os_name_returns_known_value() {
  local name
  name=$(os_name)
  if [[ "$name" != "macos" && "$name" != "linux" ]]; then
    echo "FAIL: os_name returned '$name', expected 'macos' or 'linux'" >&2
    return 1
  fi
}

test_os_name_matches_is_macos() {
  local name
  name=$(os_name)
  if is_macos; then
    assert_equals "macos" "$name"
  else
    assert_equals "linux" "$name"
  fi
}

# ── dotfiles_state_file ──

test_dotfiles_state_file_returns_path() {
  local path
  path=$(dotfiles_state_file)
  assert_contains "$path" "dotfiles/state.json"
}

test_dotfiles_state_file_macos_uses_library() {
  if is_macos; then
    local path
    path=$(dotfiles_state_file)
    assert_contains "$path" "Library/Application Support"
  fi
}

# ── package manager detection ──

test_is_brew_returns_exit_code() {
  # Should succeed on macOS with brew, fail on linux without it
  if command_exists brew; then
    assert_retval 0 is_brew
  else
    assert_retval 1 is_brew
  fi
}

run_tests
