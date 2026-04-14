#!/usr/bin/env bash
# lib/link.sh — symlink helpers

# safe_link <src> <dst>
# Creates a symlink from src to dst.
# - If dst is already our symlink → remove and re-link
# - If dst is a regular file → rename to dst.bak, echo backup path to stdout
# - If dst does not exist → link directly
# Creates parent directories as needed.
# Echoes backup path to stdout if a backup was made (empty otherwise).
safe_link() {
  local src="$1"
  local dst="$2"
  local backup=""

  ensure_dir "$(dirname "$dst")" >&2

  if [[ -L "$dst" ]]; then
    # Already a symlink — remove it (we'll re-link below)
    rm "$dst"
  elif [[ -f "$dst" ]]; then
    # Regular file — back it up
    local bak="${dst}.bak"
    info "Backing up $dst → $bak" >&2
    mv "$dst" "$bak"
    backup="$bak"
  fi

  info "Linking $src → $dst" >&2
  ln -sf "$src" "$dst"
  ok "Linked $(basename "$dst")" >&2

  echo "$backup"
}

# safe_unlink <dst>
# Removes a symlink. Warns if dst is not a symlink.
safe_unlink() {
  local dst="$1"
  if [[ -L "$dst" ]]; then
    rm "$dst"
    ok "Removed link $dst"
  elif [[ -e "$dst" ]]; then
    warn "$dst is not a symlink — skipping removal"
  else
    warn "$dst does not exist — skipping removal"
  fi
}
