#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$TESTS_DIR/unit.sh"

# ── command_exists ──

test_command_exists_finds_bash() {
  assert_retval 0 command_exists bash
}

test_command_exists_rejects_nonexistent() {
  assert_retval 1 command_exists __no_such_command_xyz__
}

# ── ensure_dir ──

test_ensure_dir_creates_directory() {
  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" RETURN
  local target="$tmp/sub/deep"
  ensure_dir "$target"
  assert_file_exists "$target"
}

test_ensure_dir_noop_on_existing() {
  local tmp
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" RETURN
  ensure_dir "$tmp"
  assert_file_exists "$tmp"
}

# ── add_line_to_file ──

test_add_line_to_file_creates_entry() {
  local tmp
  tmp=$(mktemp)
  trap "rm -f '$tmp'" RETURN
  add_line_to_file "hello world" "$tmp"
  local content
  content=$(cat "$tmp")
  assert_contains "$content" "hello world"
}

test_add_line_to_file_is_idempotent() {
  local tmp
  tmp=$(mktemp)
  trap "rm -f '$tmp'" RETURN
  add_line_to_file "unique line" "$tmp"
  add_line_to_file "unique line" "$tmp"
  local count
  count=$(grep -c "unique line" "$tmp")
  assert_equals "1" "$count"
}

test_add_line_to_file_appends_different_lines() {
  local tmp
  tmp=$(mktemp)
  trap "rm -f '$tmp'" RETURN
  add_line_to_file "line one" "$tmp"
  add_line_to_file "line two" "$tmp"
  local count
  count=$(wc -l < "$tmp" | tr -d ' ')
  assert_equals "2" "$count"
}

# ── is_ci ──

test_is_ci_false_by_default() {
  (
    unset CI GITHUB_ACTIONS
    assert_retval 1 is_ci
  )
}

test_is_ci_true_when_CI_set() {
  (
    export CI=true
    assert_retval 0 is_ci
  )
}

test_is_ci_true_when_GITHUB_ACTIONS_set() {
  (
    export GITHUB_ACTIONS=true
    assert_retval 0 is_ci
  )
}

# ── dotfiles_dir ──

test_dotfiles_dir_returns_value() {
  local result
  result=$(dotfiles_dir)
  assert_equals "$DOTFILES_DIR" "$result"
}

# ── download_file ──

test_download_file_rejects_missing_tools() {
  (
    # Override command_exists to always fail
    command_exists() { return 1; }
    assert_retval 1 download_file "http://example.com" "/dev/null"
  )
}

run_tests
