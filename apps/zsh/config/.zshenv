# .zshenv — loaded for every zsh invocation (login, interactive, scripts)
# Keep this minimal: only environment variables needed universally.

export PATH="$HOME/.local/bin:$PATH"

# XDG base dirs
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"
