#!/usr/bin/env bash
# Runs before the recorded artifacts are removed, while zsh still exists.
# A login shell that is about to be deleted has to be pointed somewhere real
# first, or the next login lands in a broken session.

_zsh_fallback_shell="/bin/bash"
if is_macos; then
  # the system zsh, which brew never owns and never removes
  _zsh_fallback_shell="/bin/zsh"
fi

if [[ "$SHELL" == "$_zsh_fallback_shell" ]]; then
  info "Login shell is already $_zsh_fallback_shell"
elif [[ ! -x "$_zsh_fallback_shell" ]]; then
  warn "$_zsh_fallback_shell not found — set your login shell manually before logging out"
else
  info "Restoring login shell to $_zsh_fallback_shell"
  chsh -s "$_zsh_fallback_shell"
fi

unset _zsh_fallback_shell
