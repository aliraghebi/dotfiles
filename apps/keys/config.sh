#!/usr/bin/env bash

printf "  GitHub username [aliraghebi]: "
read -r _keys_username
_keys_username="${_keys_username:-aliraghebi}"

step "Fetching SSH keys for ${_keys_username}"

_keys_tmpfile=$(mktemp)
download_file "https://github.com/${_keys_username}.keys" "$_keys_tmpfile"

if [[ ! -s "$_keys_tmpfile" ]]; then
  rm -f "$_keys_tmpfile"
  error "No SSH keys found for GitHub user: ${_keys_username}"
  exit 1
fi

if [[ ! -d "$HOME/.ssh" ]]; then
  ensure_dir "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi

if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
  touch "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

while IFS= read -r _keys_line; do
  [[ -z "$_keys_line" ]] && continue
  add_line_to_file "$_keys_line" "$HOME/.ssh/authorized_keys"
done < "$_keys_tmpfile"

rm -f "$_keys_tmpfile"
ok "SSH keys from ${_keys_username} added to ~/.ssh/authorized_keys"
