#!/usr/bin/env bash
# lib/state.sh — state file management via jq (JSON only)

_state_file() {
  dotfiles_state_file
}

_state_ensure_file() {
  local file
  file=$(_state_file)
  local dir
  dir=$(dirname "$file")
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi
  if [[ ! -f "$file" ]]; then
    echo '{}' > "$file"
  fi
}

_state_read() {
  local file
  file=$(_state_file)
  if [[ ! -f "$file" ]]; then
    echo '{}'
    return
  fi
  cat "$file"
}

_state_write() {
  local content="$1"
  local file
  file=$(_state_file)
  local tmp
  tmp="${file}.tmp.$$"
  echo "$content" > "$tmp"
  mv "$tmp" "$file"
}

state_get_status() {
  local app="$1"
  _state_read | jq -r --arg app "$app" '.[$app].status // empty'
}

state_set_status() {
  local app="$1"
  local status="$2"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg status "$status" \
    'if .[$app] then .[$app].status = $status else .[$app] = {"status": $status, "links": [], "backups": []} end')
  _state_write "$updated"
}

state_set_configured() {
  local app="$1"
  _state_ensure_file
  local current
  current=$(_state_read)
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg ts "$ts" \
    'if .[$app] then .[$app].status = "configured" | .[$app].configured_at = $ts
     else .[$app] = {"status": "configured", "configured_at": $ts, "links": [], "backups": []} end')
  _state_write "$updated"
}

state_add_link() {
  local app="$1"
  local src="$2"
  local dst="$3"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg src "$src" \
    --arg dst "$dst" \
    'if .[$app] then .[$app].links += [{"src": $src, "dst": $dst}]
     else .[$app] = {"status": "configuring", "links": [{"src": $src, "dst": $dst}], "backups": []} end')
  _state_write "$updated"
}

state_remove_link() {
  local app="$1"
  local dst="$2"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg dst "$dst" \
    'if .[$app] then .[$app].links = [.[$app].links[] | select(.dst != $dst)] else . end')
  _state_write "$updated"
}

state_add_backup() {
  local app="$1"
  local original="$2"
  local backup="$3"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg orig "$original" \
    --arg bak "$backup" \
    'if .[$app] then .[$app].backups += [{"original": $orig, "backup": $bak}]
     else .[$app] = {"status": "configuring", "links": [], "backups": [{"original": $orig, "backup": $bak}]} end')
  _state_write "$updated"
}

state_remove_backup() {
  local app="$1"
  local original="$2"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq \
    --arg app "$app" \
    --arg orig "$original" \
    'if .[$app] then .[$app].backups = [.[$app].backups[] | select(.original != $orig)] else . end')
  _state_write "$updated"
}

state_get_links() {
  local app="$1"
  _state_read | jq -c --arg app "$app" '.[$app].links // []'
}

state_get_backups() {
  local app="$1"
  _state_read | jq -c --arg app "$app" '.[$app].backups // []'
}

state_remove_app() {
  local app="$1"
  _state_ensure_file
  local current
  current=$(_state_read)
  local updated
  updated=$(echo "$current" | jq --arg app "$app" 'del(.[$app])')
  _state_write "$updated"
}

state_list_configured() {
  _state_read | jq -r 'to_entries[] | .key' 2>/dev/null || true
}
