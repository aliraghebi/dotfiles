#!/usr/bin/env bash
# lib/pkg.sh — idempotent package install/upgrade helpers
#
# Every require_* helper runs in one of two modes. In "install" mode an
# already-present package is a no-op; in "upgrade" mode it is moved to the
# latest version instead of being skipped. `dotfiles upgrade` flips the mode,
# so apps get upgrade support from their existing install.sh for free.
#
# Installing also *records* what landed on the machine, as an artifact in the
# state file. `dotfiles uninstall` reverses those records — it never re-runs
# install.sh, so install code can never run while removing something.

_PKG_MODE="install"
_PKG_APP=""
_APT_REFRESHED=false

# pkg_set_mode <install|upgrade>
pkg_set_mode() {
  local mode="$1"
  case "$mode" in
    install|upgrade) _PKG_MODE="$mode" ;;
    *) error "Unknown package mode: $mode"; return 1 ;;
  esac
}

# True while running under `dotfiles upgrade` — apps with hand-rolled installs
# use this to re-run instead of skipping when the software is already present.
pkg_upgrading() {
  [[ "$_PKG_MODE" == "upgrade" ]]
}

# pkg_set_app <app|""> — whose artifacts the require_* helpers are recording.
# Set by the install dispatch; empty means "record nothing".
pkg_set_app() {
  _PKG_APP="$1"
}

# pkg_record <kind> <id> [owned]
# Records one install artifact against the app being dispatched. require_*
# calls this for you; hand-rolled install steps call it directly for whatever
# they drop on the machine (a cloned directory, a repo file, a binary).
# <kind> must be one that pkg_remove_artifact knows how to reverse.
# <owned> defaults to true — pass false when the thing was already there.
pkg_record() {
  local kind="$1"
  local id="$2"
  local owned="${3:-true}"
  [[ -n "$_PKG_APP" ]] || return 0
  state_add_artifact "$_PKG_APP" "$kind" "$id" "$owned"
}

# pkg_remove_artifact <kind> <id> — reverse one recorded artifact.
# Missing tools and already-gone targets are reported, not fatal: uninstall
# must keep going through the rest of the list.
pkg_remove_artifact() {
  local kind="$1"
  local id="$2"

  case "$kind" in
    brew|brew_cask)
      if ! command_exists brew; then
        warn "brew is gone — cannot remove $id"
        return 0
      fi
      ;;
    apt)
      if ! dpkg -s "$id" >/dev/null 2>&1; then
        info "$id is not installed via apt"
        return 0
      fi
      ;;
    pacman)
      if ! pacman -Qi "$id" >/dev/null 2>&1; then
        info "$id is not installed via pacman"
        return 0
      fi
      ;;
    path|root_path)
      # An empty or bare-root id would turn this into an rm -rf disaster
      if [[ "$id" != /* || "$id" == "/" ]]; then
        error "Refusing to remove unsafe path: '$id'"
        return 1
      fi
      if [[ ! -e "$id" ]]; then
        info "$id is already gone"
        return 0
      fi
      ;;
  esac

  case "$kind" in
    brew)
      info "Uninstalling $id via brew"
      brew uninstall "$id"
      ;;
    brew_cask)
      info "Uninstalling $id via brew cask"
      brew uninstall --cask "$id"
      ;;
    apt)
      # remove, not purge — /etc config left behind on purpose
      info "Removing $id via apt"
      sudo apt-get remove -y "$id"
      ;;
    pacman)
      # -Rs drops orphaned deps but keeps config files
      info "Removing $id via pacman"
      sudo pacman -Rs --noconfirm "$id"
      ;;
    cargo)
      info "Uninstalling $id via cargo"
      cargo uninstall "$id"
      ;;
    npm)
      info "Uninstalling $id via npm"
      npm uninstall -g "$id"
      ;;
    pip)
      info "Uninstalling $id via pip"
      pip3 uninstall -y "$id"
      ;;
    path)
      info "Removing $id"
      rm -rf "$id"
      ;;
    root_path)
      info "Removing $id"
      sudo rm -rf "$id"
      ;;
    *)
      error "Unknown artifact kind: '$kind'"
      return 1
      ;;
  esac
}

# apt package lists must be fresh before an upgrade; refresh at most once per run
_apt_refresh() {
  [[ "$_APT_REFRESHED" == true ]] && return 0
  info "Refreshing apt package lists"
  sudo apt-get update -y
  _APT_REFRESHED=true
}

require_brew() {
  local pkg="$1"
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    if pkg_upgrading; then
      info "Upgrading $pkg via brew"
      brew upgrade "$pkg"
    else
      info "$pkg already installed via brew"
    fi
    pkg_record brew "$pkg" false
    return 0
  fi
  info "Installing $pkg via brew"
  brew install "$pkg"
  pkg_record brew "$pkg"
}

brew_cask_installed() {
  brew list --cask "$1" >/dev/null 2>&1
}

require_brew_cask() {
  local pkg="$1"
  if brew_cask_installed "$pkg"; then
    if pkg_upgrading; then
      # Casks that update themselves are left alone — brew skips them without --greedy
      info "Upgrading $pkg via brew cask"
      brew upgrade --cask "$pkg"
    else
      info "$pkg already installed via brew cask"
    fi
    pkg_record brew_cask "$pkg" false
    return 0
  fi
  info "Installing $pkg via brew cask"
  local output
  if ! output=$(brew install --cask "$pkg" 2>&1); then
    if echo "$output" | grep -q "there is already"; then
      warn "$pkg: files already exist on disk, skipping"
      return 0
    fi
    echo "$output" >&2
    return 1
  fi
  echo "$output"
  pkg_record brew_cask "$pkg"
}

require_brew_tap() {
  local tap="$1"
  local pkg="$2"
  # The tap itself is never recorded — other formulae may still come from it
  if ! brew tap | grep -q "^${tap}$" 2>/dev/null; then
    info "Tapping $tap"
    brew tap "$tap"
  fi
  require_brew "$pkg"
}

require_apt() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    if pkg_upgrading; then
      _apt_refresh
      info "Upgrading $pkg via apt"
      sudo apt-get install -y --only-upgrade "$pkg"
    else
      info "$pkg already installed via apt"
    fi
    pkg_record apt "$pkg" false
    return 0
  fi
  info "Installing $pkg via apt"
  sudo apt-get install -y "$pkg"
  pkg_record apt "$pkg"
}

require_cargo() {
  local crate="$1"
  if command_exists "$crate"; then
    if pkg_upgrading; then
      info "Upgrading $crate via cargo"
      cargo install --force "$crate"
    else
      info "$crate already installed via cargo"
    fi
    pkg_record cargo "$crate" false
    return 0
  fi
  info "Installing $crate via cargo"
  cargo install "$crate"
  pkg_record cargo "$crate"
}

require_go() {
  local module="$1"
  local bin
  bin=$(basename "$module" | cut -d@ -f1)
  # go install has no uninstall — what it leaves is a single binary under GOBIN
  local gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
  if command_exists "$bin"; then
    if pkg_upgrading; then
      info "Upgrading $bin via go"
      go install "${module%@*}@latest"
    else
      info "$bin already installed via go"
    fi
    pkg_record path "$gobin/$bin" false
    return 0
  fi
  info "Installing $module via go"
  go install "$module"
  pkg_record path "$gobin/$bin"
}

# Strips a pinned version, but not the leading @ of a scoped package
_npm_base() {
  local pkg="$1"
  [[ "${pkg#?}" == *@* ]] && pkg="${pkg%@*}"
  echo "$pkg"
}

require_npm() {
  local pkg="$1"
  local bin="${2:-$(basename "$pkg")}"
  local base
  base=$(_npm_base "$pkg")
  if command_exists "$bin"; then
    if pkg_upgrading; then
      info "Upgrading $bin via npm"
      npm install -g "${base}@latest"
    else
      info "$bin already installed via npm"
    fi
    pkg_record npm "$base" false
    return 0
  fi
  info "Installing $pkg via npm"
  npm install -g "$pkg"
  pkg_record npm "$base"
}

require_pip() {
  local pkg="$1"
  if pip3 show "$pkg" >/dev/null 2>&1; then
    if pkg_upgrading; then
      info "Upgrading $pkg via pip"
      pip3 install --user --upgrade "$pkg"
    else
      info "$pkg already installed via pip"
    fi
    pkg_record pip "$pkg" false
    return 0
  fi
  info "Installing $pkg via pip"
  pip3 install --user "$pkg"
  pkg_record pip "$pkg"
}

require_pacman() {
  local pkg="$1"
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    if pkg_upgrading; then
      # Arch does not support partial upgrades — -Syu is the only safe form
      info "Upgrading $pkg via pacman"
      sudo pacman -Syu --noconfirm "$pkg"
    else
      info "$pkg already installed via pacman"
    fi
    pkg_record pacman "$pkg" false
    return 0
  fi
  info "Installing $pkg via pacman"
  sudo pacman -S --noconfirm "$pkg"
  pkg_record pacman "$pkg"
}

# require_gh_release <owner/repo> <binary> [asset_template]
# Without asset_template: auto-detects asset by OS name, installs binary to ~/.local/bin.
# With asset_template: evaluates the template with $version set from the latest release tag,
#   installs .deb via dpkg or drops a plain binary into ~/.local/bin.
# In upgrade mode the latest release is always re-fetched — GitHub releases carry
# no locally comparable version, so reinstall is the only reliable refresh.
# Examples:
#   require_gh_release "cli/cli" "gh"
#   require_gh_release "gopasspw/gopass" "gopass" 'gopass_${version#v}_linux_amd64.deb'
require_gh_release() {
  local repo="$1"
  local binary="$2"
  local asset_tpl="${3:-}"

  if command_exists "$binary" && ! pkg_upgrading; then
    info "$binary already installed"
    # Only the plain-binary path is recognisable after the fact; a .deb went
    # to dpkg and is recorded below when we are the ones installing it.
    if [[ -e "$HOME/.local/bin/$binary" ]]; then
      pkg_record path "$HOME/.local/bin/$binary" false
    fi
    return 0
  fi

  info "Fetching latest $binary release from $repo"

  local version asset url tmp
  version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r '.tag_name')

  if [[ -z "$version" ]]; then
    error "Could not determine latest $binary version"
    return 1
  fi

  if [[ -n "$asset_tpl" ]]; then
    asset=$(eval echo "$asset_tpl")
    url="https://github.com/${repo}/releases/download/${version}/${asset}"
  else
    url=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
      | jq -r ".assets[] | select(.name | contains(\"$(uname -s | tr '[:upper:]' '[:lower:]')\")) | .browser_download_url" \
      | head -1)
    asset=$(basename "$url")
  fi

  if [[ -z "$url" ]]; then
    error "Could not find release asset for $repo"
    return 1
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  info "Downloading ${asset}"
  curl -fsSL -o "${tmp}/${asset}" "${url}"

  if [[ "$asset" == *.deb ]]; then
    sudo dpkg -i "${tmp}/${asset}"
    # The dpkg package name is what apt needs later, and only the .deb knows it
    local deb_pkg
    deb_pkg=$(dpkg-deb -f "${tmp}/${asset}" Package)
    pkg_record apt "$deb_pkg"
  else
    ensure_dir "$HOME/.local/bin"
    mv "${tmp}/${asset}" "$HOME/.local/bin/$binary"
    chmod +x "$HOME/.local/bin/$binary"
    pkg_record path "$HOME/.local/bin/$binary"
  fi

  ok "$binary ${version} installed"
}

# require_script <url> [interpreter] [args...]
# Nothing is recorded — a vendor script can drop anything anywhere. Callers that
# know what it leaves behind should pkg_record it themselves.
require_script() {
  local url="$1"
  local interpreter="${2:-sh}"
  shift $(( $# > 1 ? 2 : 1 ))
  info "Running install script from $url"
  curl -fsSL "$url" | "$interpreter" "$@"
}
