# .zshrc — interactive shell configuration

# Oh My Zsh
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  # set name of the theme to load. Optionally, if you set this to "random"
  # it'll load a random theme each time that oh-my-zsh is loaded.
  # see https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
  ZSH_THEME="gnzh"
fi

plugins=(git brew macos colored-man-pages golang zsh-autosuggestions)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

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

# partial history search bindings
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# Completion
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# XTERM
TERM=xterm-256color

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
