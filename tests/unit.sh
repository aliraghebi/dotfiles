#!/usr/bin/env bash
# tests/unit.sh — minimal bash unit test framework
# Inspired by github.com/1995parham/dotfiles test structure
set -euo pipefail

_test_passed=0
_test_failed=0
_test_total=0
_test_failures=()

assert_equals() {
  if [[ $# -ne 2 ]]; then
    echo "  FAIL: assert_equals requires 2 arguments" >&2
    return 1
  fi
  local expected="$1"
  local actual="$2"
  if [[ "$expected" != "$actual" ]]; then
    echo "  FAIL: expected '$expected', got '$actual'" >&2
    return 1
  fi
}

assert_retval() {
  local expected="$1"
  shift
  local actual
  set +e
  "$@" >/dev/null 2>&1
  actual=$?
  set -e
  if [[ "$actual" -ne "$expected" ]]; then
    echo "  FAIL: expected exit code $expected from '$*', got $actual" >&2
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  FAIL: '$haystack' does not contain '$needle'" >&2
    return 1
  fi
}

assert_file_exists() {
  if [[ ! -e "$1" ]]; then
    echo "  FAIL: file '$1' does not exist" >&2
    return 1
  fi
}

assert_symlink() {
  if [[ ! -L "$1" ]]; then
    echo "  FAIL: '$1' is not a symlink" >&2
    return 1
  fi
}

assert_not_exists() {
  if [[ -e "$1" ]]; then
    echo "  FAIL: '$1' should not exist" >&2
    return 1
  fi
}

# Run all test_ functions discovered in the calling script
run_tests() {
  local func
  while IFS= read -r func; do
    func="${func#declare -f }"
    [[ "$func" == test_* ]] || continue
    (( _test_total++ )) || true

    set +e
    output=$("$func" 2>&1)
    local rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
      (( _test_passed++ )) || true
      printf "  ✓ %s\n" "$func"
    else
      (( _test_failed++ )) || true
      printf "  ✗ %s\n" "$func"
      _test_failures+=("$func: $output")
    fi
  done < <(declare -F)

  echo ""
  if [[ $_test_failed -eq 0 ]]; then
    printf "All %d tests passed.\n" "$_test_total"
  else
    printf "%d passed, %d failed (of %d).\n" "$_test_passed" "$_test_failed" "$_test_total"
    echo ""
    for f in "${_test_failures[@]}"; do
      echo "  $f"
    done
    exit 1
  fi
}
