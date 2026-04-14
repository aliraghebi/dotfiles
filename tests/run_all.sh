#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0

for test_file in "$TESTS_DIR"/test_*.sh; do
  name=$(basename "$test_file")
  printf "\n── %s ──\n" "$name"
  if bash "$test_file"; then
    :
  else
    failed=1
  fi
done

echo ""
if [[ $failed -eq 0 ]]; then
  echo "All test suites passed."
else
  echo "Some test suites failed."
  exit 1
fi
