#!/usr/bin/env bash
set -euo pipefail

# Bootstrap: installs prerequisites, clones the dotfiles repo, symlinks the CLI.
# Works both when curled remotely and when run locally from the repo.
#
# Remote usage:
#   sudo bash -c "$(curl -sL https://github.com/aliraghebiii/dotfiles/raw/main/install.sh)" @ install
#
# Local usage:
#   bash install.sh
#   bash install.sh install

REPO_URL="https://github.com/aliraghebiii/dotfiles.git"
DOTFILES_TARGET=".dotfiles"

# ---------------------------------------------------------------------------
# Resolve the real user when running under sudo
# ---------------------------------------------------------------------------
_resolve_user() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    printf '%s' "$SUDO_USER"
  else
    whoami
  fi
}

_resolve_home() {
  local user
  user="$(_resolve_user)"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS: dscl is always available
    dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}'
  else
    getent passwd "$user" | cut -d: -f6
  fi
}

REAL_USER="$(_resolve_user)"
REAL_HOME="$(_resolve_home)"

if [[ -z "$REAL_HOME" ]]; then
  echo "ERROR: could not determine home directory for user '$REAL_USER'" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Minimal logging (lib not sourced yet)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  _GREEN='\033[0;32m'; _RED='\033[0;31m'; _YELLOW='\033[0;33m'; _RESET='\033[0m'; _BOLD='\033[1m'
else
  _GREEN=''; _RED=''; _YELLOW=''; _RESET=''; _BOLD=''
fi
info()  { printf "  → %s\n" "$*"; }
ok()    { printf "${_GREEN}  ✓ %s${_RESET}\n" "$*"; }
warn()  { printf "${_YELLOW}  ! %s${_RESET}\n" "$*"; }
error() { printf "${_RED}  ✗ %s${_RESET}\n" "$*" >&2; }
step()  { printf "${_BOLD}\n[ %s ]${_RESET}\n" "$*"; }

# ---------------------------------------------------------------------------
# Helper: run a command as the real user (drops root when under sudo)
# ---------------------------------------------------------------------------
_as_user() {
  if [[ "$(id -u)" -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
    sudo -u "$SUDO_USER" -- "$@"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# Detect OS and package manager
# ---------------------------------------------------------------------------
_detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

_detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v brew >/dev/null 2>&1; then
    echo "brew"
  else
    echo "unknown"
  fi
}

OS="$(_detect_os)"
PKG_MGR="$(_detect_pkg_manager)"

# ---------------------------------------------------------------------------
# Install prerequisites
# ---------------------------------------------------------------------------
step "Checking prerequisites"

_install_prereqs_macos() {
  # Xcode Command Line Tools
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    # Wait for installation to complete
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
    ok "Xcode Command Line Tools installed"
  else
    ok "Xcode Command Line Tools present"
  fi

  # Check for required tools — brew is optional on macOS (git/curl/jq come with CLT)
  local missing=""
  local tool
  for tool in git curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing="$missing $tool"
    fi
  done

  if [[ -n "$missing" ]]; then
    if command -v brew >/dev/null 2>&1; then
      info "Installing missing tools via brew:$missing"
      # shellcheck disable=SC2086
      brew install $missing
    else
      error "Missing tools:$missing"
      error "Install Homebrew first: https://brew.sh"
      exit 1
    fi
  fi
}

_install_prereqs_linux_apt() {
  info "Installing prerequisites via apt..."
  apt-get update -qq
  apt-get install -y git curl jq
}

_install_prereqs_linux_pacman() {
  info "Installing prerequisites via pacman..."
  pacman -S --noconfirm git curl jq
}

_install_prereqs_linux() {
  local missing=""
  local tool
  for tool in git curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing="$missing $tool"
    fi
  done

  if [[ -z "$missing" ]]; then
    return
  fi

  case "$PKG_MGR" in
    apt)    _install_prereqs_linux_apt ;;
    pacman) _install_prereqs_linux_pacman ;;
    *)
      error "Missing tools:$missing"
      error "Could not detect a supported package manager (apt-get or pacman)"
      exit 1
      ;;
  esac
}

case "$OS" in
  macos) _install_prereqs_macos ;;
  linux) _install_prereqs_linux ;;
  *)
    error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

ok "Prerequisites satisfied (git, curl, jq)"

# ---------------------------------------------------------------------------
# Determine if we are running from inside the repo or remotely (curl)
# ---------------------------------------------------------------------------
_is_inside_repo() {
  # If BASH_SOURCE is empty or set to stdin-like values, we are piped via curl
  local src="${BASH_SOURCE[0]:-}"
  if [[ -z "$src" ]] || [[ "$src" == "bash" ]] || [[ "$src" == "-bash" ]]; then
    return 1
  fi
  # Check if the script's directory contains bin/dotfiles (i.e., it's the repo)
  local dir
  dir="$(cd "$(dirname "$src")" && pwd)"
  if [[ -f "$dir/bin/dotfiles" ]]; then
    return 0
  fi
  return 1
}

DOTFILES_DIR="$REAL_HOME/$DOTFILES_TARGET"

if _is_inside_repo; then
  # Running locally from within the repo — resolve DOTFILES_DIR from script location
  _resolve_dir() {
    local src="$1"
    local dir
    while [[ -L "$src" ]]; do
      dir=$(cd "$(dirname "$src")" && pwd)
      src=$(readlink "$src")
      if [[ "$src" != /* ]]; then
        src="$dir/$src"
      fi
    done
    cd "$(dirname "$src")" && pwd
  }
  DOTFILES_DIR="$(_resolve_dir "${BASH_SOURCE[0]}")"
  info "Running locally from $DOTFILES_DIR"
else
  # Running remotely via curl — clone or update the repo
  step "Setting up dotfiles repository"

  if [[ -d "$DOTFILES_DIR" ]]; then
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
      info "Updating existing repo at $DOTFILES_DIR..."
      _as_user git -C "$DOTFILES_DIR" pull --ff-only
      ok "Repository updated"
    else
      error "$DOTFILES_DIR exists but is not a git repository"
      error "Please remove or rename it and try again"
      exit 1
    fi
  else
    info "Cloning $REPO_URL to $DOTFILES_DIR..."
    _as_user git clone "$REPO_URL" "$DOTFILES_DIR"
    ok "Repository cloned"
  fi
fi

export DOTFILES_DIR

# ---------------------------------------------------------------------------
# Symlink CLI
# ---------------------------------------------------------------------------
step "Installing dotfiles CLI"

LOCAL_BIN="$REAL_HOME/.local/bin"
_as_user mkdir -p "$LOCAL_BIN"

CLI_SRC="$DOTFILES_DIR/bin/dotfiles"
CLI_DST="$LOCAL_BIN/dotfiles"

_as_user chmod +x "$CLI_SRC"
_as_user ln -sf "$CLI_SRC" "$CLI_DST"
ok "Symlinked $CLI_SRC → $CLI_DST"

# ---------------------------------------------------------------------------
# PATH check
# ---------------------------------------------------------------------------
if echo ":$PATH:" | grep -q ":$LOCAL_BIN:"; then
  ok "$LOCAL_BIN is in your PATH"
else
  warn "$LOCAL_BIN is not in your PATH"
  echo ""
  echo "  Add this to your shell config (~/.zshrc, ~/.bashrc, etc.):"
  echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
  echo "  Then reload your shell:"
  echo "    source ~/.zshrc  # or source ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# Forward command to the CLI if arguments were provided
# ---------------------------------------------------------------------------
if [[ $# -gt 0 ]]; then
  step "Running: dotfiles $*"
  _as_user "$CLI_DST" "$@"
else
  echo ""
  ok "dotfiles CLI installed. Run: dotfiles list"
fi
