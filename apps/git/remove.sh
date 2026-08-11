#!/usr/bin/env bash
# Drop only the key config.sh set — config.local may hold other local settings.
GIT_LOCAL_CONFIG="$HOME/.config/git/config.local"

if git config --file "$GIT_LOCAL_CONFIG" --get credential.helper >/dev/null 2>&1; then
  info "Removing git credential helper"
  git config --file "$GIT_LOCAL_CONFIG" --unset-all credential.helper
  ok "Credential helper removed"
fi
