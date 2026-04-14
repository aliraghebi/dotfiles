#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/link.sh"
source "$TESTS_DIR/unit.sh"

_tmpdir=""

_setup() {
  _tmpdir=$(mktemp -d)
}

_teardown() {
  [[ -n "$_tmpdir" ]] && rm -rf "$_tmpdir"
}

# ── safe_link ──

test_safe_link_creates_symlink() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source_file"
  local dst="$_tmpdir/link_file"
  echo "content" > "$src"
  safe_link "$src" "$dst" >/dev/null 2>&1
  assert_symlink "$dst"
}

test_safe_link_target_matches_source() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source_file"
  local dst="$_tmpdir/link_file"
  echo "content" > "$src"
  safe_link "$src" "$dst" >/dev/null 2>&1
  local target
  target=$(readlink "$dst")
  assert_equals "$src" "$target"
}

test_safe_link_replaces_existing_symlink() {
  _setup; trap _teardown RETURN
  local src1="$_tmpdir/file1"
  local src2="$_tmpdir/file2"
  local dst="$_tmpdir/link"
  echo "one" > "$src1"
  echo "two" > "$src2"
  safe_link "$src1" "$dst" >/dev/null 2>&1
  safe_link "$src2" "$dst" >/dev/null 2>&1
  local target
  target=$(readlink "$dst")
  assert_equals "$src2" "$target"
}

test_safe_link_backs_up_regular_file() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source_file"
  local dst="$_tmpdir/existing_file"
  echo "source content" > "$src"
  echo "existing content" > "$dst"
  local backup
  backup=$(safe_link "$src" "$dst" 2>/dev/null)
  assert_file_exists "${dst}.bak"
  assert_symlink "$dst"
  local bak_content
  bak_content=$(cat "${dst}.bak")
  assert_equals "existing content" "$bak_content"
}

test_safe_link_returns_backup_path() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source"
  local dst="$_tmpdir/target"
  echo "s" > "$src"
  echo "t" > "$dst"
  local backup
  backup=$(safe_link "$src" "$dst" 2>/dev/null)
  assert_equals "${dst}.bak" "$backup"
}

test_safe_link_returns_empty_when_no_backup() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source"
  local dst="$_tmpdir/target"
  echo "s" > "$src"
  local backup
  backup=$(safe_link "$src" "$dst" 2>/dev/null)
  assert_equals "" "$backup"
}

test_safe_link_creates_parent_directories() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source"
  local dst="$_tmpdir/sub/deep/link"
  echo "content" > "$src"
  safe_link "$src" "$dst" >/dev/null 2>&1
  assert_symlink "$dst"
}

# ── safe_unlink ──

test_safe_unlink_removes_symlink() {
  _setup; trap _teardown RETURN
  local src="$_tmpdir/source"
  local dst="$_tmpdir/link"
  echo "content" > "$src"
  ln -sf "$src" "$dst"
  safe_unlink "$dst" >/dev/null 2>&1
  assert_not_exists "$dst"
}

test_safe_unlink_skips_regular_file() {
  _setup; trap _teardown RETURN
  local file="$_tmpdir/regular"
  echo "content" > "$file"
  safe_unlink "$file" >/dev/null 2>&1
  # Regular file should NOT be removed
  assert_file_exists "$file"
}

test_safe_unlink_skips_nonexistent() {
  _setup; trap _teardown RETURN
  # Should not error on missing target
  assert_retval 0 safe_unlink "$_tmpdir/nonexistent"
}

run_tests
