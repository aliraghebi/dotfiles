# .zshrc — interactive shell configuration

# Path deduplication
typeset -U path

# Locale
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Editor / terminal
EDITOR="$(command -v nvim)"
export EDITOR
SUDO_EDITOR="$(command -v nvim)"
export SUDO_EDITOR
TERM=xterm-256color
export TERM

# PATH additions
[[ -d "$HOME/bin" ]] && path+=("$HOME/bin")
[[ -d "$HOME/.local/bin" ]] && path+=("$HOME/.local/bin")
[[ -d "$HOME/.cargo/bin" ]] && path+=("$HOME/.cargo/bin")

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
DISABLE_AUTO_TITLE='true'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  ZSH_THEME="gnzh"
fi

plugins=(git brew macos colored-man-pages golang zsh-autosuggestions)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Python
export VIRTUALENV_SYSTEM_SITE_PACKAGES=true

if command -v pyenv >/dev/null 2>&1 && [[ -z "$VIRTUAL_ENV" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  path=("$PYENV_ROOT/bin" "${path[@]}")
  eval "$(pyenv init -)"
fi

# Cloud / Kubernetes
export AWS_VAULT_BACKEND=file
[[ -f "$HOME/.kube/k3s.yaml" ]] && export KUBECONFIG="$HOME/.kube/k3s.yaml"

if command -v k9s >/dev/null 2>&1; then
  export K9S_CONFIG_DIR="$HOME/.config/k9s"
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# Completion
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Aliases
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi

alias ll='ls -lAh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias vim='nvim'
alias vi='nvim'

# Local overrides (not tracked in dotfiles)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
