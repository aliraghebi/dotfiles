#!/usr/bin/env bash
# lib/utils.sh — general utility helpers

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    info "Creating directory: $path" >&2
    mkdir -p "$path"
  fi
}

download_file() {
  local url="$1"
  local dest="$2"
  if command_exists curl; then
    curl -fsSL "$url" -o "$dest"
  elif command_exists wget; then
    wget -qO "$dest" "$url"
  else
    error "Neither curl nor wget found — cannot download $url"
    return 1
  fi
}

add_line_to_file() {
  local line="$1"
  local file="$2"
  if [[ -f "$file" ]] && grep -qF "$line" "$file" 2>/dev/null; then
    return 0
  fi
  echo "$line" >> "$file"
}

is_ci() {
  [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]
}

dotfiles_dir() {
  echo "$DOTFILES_DIR"
}
