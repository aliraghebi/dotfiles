#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$TESTS_DIR/unit.sh"

# ── info ──

test_info_outputs_message() {
  local output
  output=$(info "test message" 2>&1)
  assert_contains "$output" "test message"
}

# ── ok ──

test_ok_outputs_message() {
  local output
  output=$(ok "success" 2>&1)
  assert_contains "$output" "success"
}

# ── warn ──

test_warn_outputs_message() {
  local output
  output=$(warn "warning" 2>&1)
  assert_contains "$output" "warning"
}

# ── error ──

test_error_outputs_to_stderr() {
  local output
  output=$(error "bad thing" 2>&1)
  assert_contains "$output" "bad thing"
}

# ── step ──

test_step_outputs_message() {
  local output
  output=$(step "Installing" 2>&1)
  assert_contains "$output" "Installing"
}

# ── Colors suppressed in non-TTY ──

test_colors_empty_in_pipe() {
  # When piped (non-TTY), color vars should be empty
  local output
  output=$(bash -c 'source "'"$DOTFILES_DIR"'/lib/log.sh"; echo "[$_CYAN][$_GREEN][$_RESET]"' | cat)
  assert_equals "[][][]" "$output"
}

run_tests
