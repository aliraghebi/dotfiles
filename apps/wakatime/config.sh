#!/usr/bin/env bash
set -euo pipefail

WAKATIME_CFG="$HOME/.wakatime.cfg"

if [[ ! -f "$WAKATIME_CFG" ]]; then
  cat > "$WAKATIME_CFG" <<'EOF'
[settings]
debug = false
api_key =
hidefilenames = false
ignore =
    COMMIT_EDITMSG$
    PULLREQ_EDITMSG$
    MERGE_MSG$
    TAG_EDITMSG$

status_bar_coding_activity = true
status_bar_enabled = true
disabled = false
EOF
  ok "Created $WAKATIME_CFG"
fi

if grep -qE '^api_key =.+' "$WAKATIME_CFG" 2>/dev/null; then
  ok "WakaTime API key already set"
else
  step "Enter your WakaTime API key:"
  read -r WAKATIME_API_KEY
  if [[ -z "$WAKATIME_API_KEY" ]]; then
    warn "No API key provided — run 'dotfiles config wakatime' to set it later"
  else
    sed -i.bak "s|^api_key =.*|api_key = $WAKATIME_API_KEY|" "$WAKATIME_CFG"
    rm -f "$WAKATIME_CFG.bak"
    ok "WakaTime API key saved to $WAKATIME_CFG"
  fi
fi
