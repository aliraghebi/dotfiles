#!/usr/bin/env bash
set -euo pipefail

# kitty's terminfo is not in the system database on macOS; install it to
# ~/.terminfo so ncurses apps and sudo sessions can resolve xterm-kitty.
if is_macos; then
  terminfo_src="/Applications/kitty.app/Contents/Resources/kitty/terminfo/kitty.terminfo"
  if [[ -f "$terminfo_src" ]]; then
    tic -x -o "$HOME/.terminfo" "$terminfo_src"
    ok "kitty terminfo installed"
  else
    warn "kitty.app not found at expected path — skipping terminfo install"
  fi
fi