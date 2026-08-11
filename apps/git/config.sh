#!/usr/bin/env bash
# The credential helper is OS- and machine-specific, so it lives in the
# untracked local include rather than in the tracked config.

GIT_LOCAL_CONFIG="$HOME/.config/git/config.local"

if is_macos; then
  GIT_CRED_HELPER="osxkeychain"
elif [[ -x "$(git --exec-path)/git-credential-libsecret" ]]; then
  GIT_CRED_HELPER="libsecret"
else
  # No keyring available — memory-only, but 24h instead of git's 15min default.
  GIT_CRED_HELPER="cache --timeout=86400"
  warn "No keyring credential helper found; falling back to in-memory cache"
fi

ensure_dir "$(dirname "$GIT_LOCAL_CONFIG")"

step "Setting git credential helper ($GIT_CRED_HELPER)"
git config --file "$GIT_LOCAL_CONFIG" credential.helper "$GIT_CRED_HELPER"
ok "Credential helper configured"
