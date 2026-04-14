#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/os.sh"
source "$DOTFILES_DIR/lib/state.sh"
source "$TESTS_DIR/unit.sh"

_tmpdir=""
_orig_home=""

_setup() {
  _tmpdir=$(mktemp -d)
  _orig_home="$HOME"
  export HOME="$_tmpdir"
  # Ensure state directory exists for the fake HOME
  if [[ "$(uname -s)" == Darwin ]]; then
    mkdir -p "$_tmpdir/Library/Application Support/dotfiles"
  else
    mkdir -p "$_tmpdir/.local/state/dotfiles"
  fi
}

_teardown() {
  export HOME="$_orig_home"
  [[ -n "$_tmpdir" ]] && rm -rf "$_tmpdir"
}

# ── state_set_status / state_get_status ──

test_state_set_and_get_status() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  local status
  status=$(state_get_status "git")
  assert_equals "configuring" "$status"
}

test_state_get_status_empty_for_unknown_app() {
  _setup; trap _teardown RETURN
  _state_ensure_file
  local status
  status=$(state_get_status "nonexistent")
  assert_equals "" "$status"
}

# ── state_set_configured ──

test_state_set_configured_sets_status() {
  _setup; trap _teardown RETURN
  state_set_configured "tmux"
  local status
  status=$(state_get_status "tmux")
  assert_equals "configured" "$status"
}

test_state_set_configured_adds_timestamp() {
  _setup; trap _teardown RETURN
  state_set_configured "tmux"
  local ts
  ts=$(_state_read | jq -r '.tmux.configured_at')
  # Should be a non-empty ISO timestamp
  assert_contains "$ts" "T"
}

# ── state_add_link / state_get_links ──

test_state_add_link_and_get_links() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  state_add_link "git" "/src/.gitconfig" "/home/.gitconfig"
  local links
  links=$(state_get_links "git")
  local count
  count=$(echo "$links" | jq 'length')
  assert_equals "1" "$count"
}

test_state_add_link_multiple() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  state_add_link "git" "/src/a" "/dst/a"
  state_add_link "git" "/src/b" "/dst/b"
  local count
  count=$(state_get_links "git" | jq 'length')
  assert_equals "2" "$count"
}

# ── state_remove_link ──

test_state_remove_link() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  state_add_link "git" "/src/a" "/dst/a"
  state_add_link "git" "/src/b" "/dst/b"
  state_remove_link "git" "/dst/a"
  local count
  count=$(state_get_links "git" | jq 'length')
  assert_equals "1" "$count"
}

# ── state_add_backup / state_get_backups ──

test_state_add_backup_and_get_backups() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  state_add_backup "git" "/home/.gitconfig" "/home/.gitconfig.bak"
  local count
  count=$(state_get_backups "git" | jq 'length')
  assert_equals "1" "$count"
}

# ── state_remove_backup ──

test_state_remove_backup() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configuring"
  state_add_backup "git" "/home/.gitconfig" "/home/.gitconfig.bak"
  state_remove_backup "git" "/home/.gitconfig"
  local count
  count=$(state_get_backups "git" | jq 'length')
  assert_equals "0" "$count"
}

# ── state_remove_app ──

test_state_remove_app() {
  _setup; trap _teardown RETURN
  state_set_status "git" "configured"
  state_remove_app "git"
  local status
  status=$(state_get_status "git")
  assert_equals "" "$status"
}

# ── state_list_configured ──

test_state_list_configured() {
  _setup; trap _teardown RETURN
  state_set_configured "git"
  state_set_configured "tmux"
  local list
  list=$(state_list_configured)
  assert_contains "$list" "git"
  assert_contains "$list" "tmux"
}

test_state_list_configured_empty() {
  _setup; trap _teardown RETURN
  _state_ensure_file
  local list
  list=$(state_list_configured)
  assert_equals "" "$list"
}

run_tests
