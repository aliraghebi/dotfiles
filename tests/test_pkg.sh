#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$TESTS_DIR")"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/log.sh"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/os.sh"
source "$DOTFILES_DIR/lib/pkg.sh"
source "$DOTFILES_DIR/lib/state.sh"
source "$TESTS_DIR/unit.sh"

_tmpdir=""
_orig_home=""

# Point the state file at a throwaway HOME and name the app being recorded
_state_setup() {
  _tmpdir=$(mktemp -d)
  _orig_home="$HOME"
  export HOME="$_tmpdir"
  pkg_set_app "testapp"
}

_state_teardown() {
  pkg_set_app ""
  export HOME="$_orig_home"
  [[ -n "$_tmpdir" ]] && rm -rf "$_tmpdir"
}

_artifacts() {
  state_get_artifacts "testapp"
}

# ── require_brew idempotency ──

test_require_brew_skips_when_already_installed() {
  # Stub brew to report the package as already installed
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    echo "FAIL: brew install should not have been called" >&2
    return 1
  }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
}

test_require_brew_installs_when_missing() {
  local installed=false
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    if [[ "$1" == "install" ]]; then installed=true; return 0; fi
  }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
  assert_equals "true" "$installed"
}

# ── require_brew_cask idempotency ──

test_require_brew_cask_skips_when_already_installed() {
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    echo "FAIL: brew install should not have been called" >&2
    return 1
  }
  export -f brew
  require_brew_cask "some-cask"
  unset -f brew
}

test_require_brew_cask_installs_when_missing() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/installed"
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    if [[ "$1" == "install" ]]; then touch "$marker"; return 0; fi
  }
  export -f brew
  require_brew_cask "some-cask"
  unset -f brew
  assert_file_exists "$marker"
}

# ── require_apt idempotency ──

test_require_apt_skips_when_already_installed() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  dpkg() {
    if [[ "$1" == "-s" ]]; then return 0; fi
  }
  export -f dpkg
  require_apt "some-pkg"
  unset -f dpkg
}


test_require_apt_installs_when_missing() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  local installed=false
  dpkg() { return 1; }
  sudo() {
    shift  # drop "sudo"
    local cmd="$1"; shift
    if [[ "$cmd" == "apt-get" ]]; then installed=true; return 0; fi
  }
  export -f dpkg sudo
  require_apt "some-pkg"
  unset -f dpkg sudo
  assert_equals "true" "$installed"
}

# ── require_cargo idempotency ──

test_require_cargo_skips_when_binary_exists() {
  command_exists() { return 0; }
  export -f command_exists
  local installed=false
  cargo() { installed=true; }
  export -f cargo
  require_cargo "ripgrep"
  unset -f command_exists cargo
  assert_equals "false" "$installed"
}

test_require_cargo_installs_when_missing() {
  command_exists() { return 1; }
  export -f command_exists
  local installed=false
  cargo() { installed=true; }
  export -f cargo
  require_cargo "ripgrep"
  unset -f command_exists cargo
  assert_equals "true" "$installed"
}

# ── require_npm idempotency ──

test_require_npm_skips_when_binary_exists() {
  command_exists() { return 0; }
  export -f command_exists
  local installed=false
  npm() { installed=true; }
  export -f npm
  require_npm "@colbymchenry/codegraph" "codegraph"
  unset -f command_exists npm
  assert_equals "false" "$installed"
}

test_require_npm_installs_when_missing() {
  command_exists() { return 1; }
  export -f command_exists
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/installed"
  npm() {
    if [[ "$1" == "install" && "$2" == "-g" ]]; then touch "$marker"; return 0; fi
  }
  export -f npm
  require_npm "@colbymchenry/codegraph" "codegraph"
  unset -f command_exists npm
  assert_file_exists "$marker"
}

# ── require_script ──

test_require_script_uses_sh_by_default() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/ran"
  curl() { echo "touch \"$marker\""; }
  export -f curl
  require_script "https://example.com/install.sh"
  unset -f curl
  assert_file_exists "$marker"
}

test_require_script_uses_custom_interpreter() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/ran"
  curl() { echo "touch \"$marker\""; }
  export -f curl
  require_script "https://example.com/install.sh" /bin/bash
  unset -f curl
  assert_file_exists "$marker"
}

test_require_script_forwards_extra_args() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/args"
  curl() { echo ':'; }
  export -f curl
  sh() { echo "$*" > "$marker"; cat >/dev/null; }
  export -f sh
  require_script "https://example.com/install.sh" sh -s -- --yes
  unset -f curl sh
  assert_equals "-s -- --yes" "$(cat "$marker")"
}

# ── package mode ──

test_pkg_mode_defaults_to_install() {
  assert_retval 1 pkg_upgrading
}

test_pkg_set_mode_switches_to_upgrade() {
  pkg_set_mode upgrade
  assert_retval 0 pkg_upgrading
  pkg_set_mode install
  assert_retval 1 pkg_upgrading
}

test_pkg_set_mode_rejects_unknown_mode() {
  assert_retval 1 pkg_set_mode "sideways"
  assert_retval 1 pkg_upgrading
}

test_pkg_set_mode_rejects_uninstall() {
  # uninstall is not a package mode — it reverses recorded artifacts instead
  assert_retval 1 pkg_set_mode "uninstall"
}

# ── upgrade mode ──

test_require_brew_upgrades_when_installed() {
  local action=""
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    action="$*"
  }
  export -f brew
  pkg_set_mode upgrade
  require_brew "some-pkg"
  unset -f brew
  assert_equals "upgrade some-pkg" "$action"
}

test_require_brew_still_installs_when_missing_in_upgrade_mode() {
  local action=""
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    action="$*"
  }
  export -f brew
  pkg_set_mode upgrade
  require_brew "some-pkg"
  unset -f brew
  assert_equals "install some-pkg" "$action"
}

test_brew_cask_installed_reflects_brew_list() {
  brew() { [[ "$1" == "list" && "$3" == "present-cask" ]]; }
  export -f brew
  assert_retval 0 brew_cask_installed "present-cask"
  assert_retval 1 brew_cask_installed "absent-cask"
  unset -f brew
}

test_require_brew_cask_upgrades_when_installed() {
  local action=""
  brew() {
    if [[ "$1" == "list" ]]; then return 0; fi
    action="$*"
  }
  export -f brew
  pkg_set_mode upgrade
  require_brew_cask "some-cask"
  unset -f brew
  assert_equals "upgrade --cask some-cask" "$action"
}

test_require_apt_upgrades_when_installed() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  local action=""
  dpkg() { return 0; }
  sudo() {
    shift  # drop the sudo-invoked command name handling to the caller
    action="$action|$*"
  }
  export -f dpkg sudo
  pkg_set_mode upgrade
  require_apt "some-pkg"
  unset -f dpkg sudo
  assert_contains "$action" "install -y --only-upgrade some-pkg"
}

test_require_apt_refreshes_lists_once_per_run() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  local updates=0
  dpkg() { return 0; }
  sudo() {
    shift
    [[ "$1" == "update" ]] && updates=$((updates + 1))
    return 0
  }
  export -f dpkg sudo
  pkg_set_mode upgrade
  require_apt "pkg-a"
  require_apt "pkg-b"
  unset -f dpkg sudo
  assert_equals "1" "$updates"
}

test_require_cargo_upgrades_with_force() {
  command_exists() { return 0; }
  export -f command_exists
  local action=""
  cargo() { action="$*"; }
  export -f cargo
  pkg_set_mode upgrade
  require_cargo "ripgrep"
  unset -f command_exists cargo
  assert_equals "install --force ripgrep" "$action"
}

test_require_npm_upgrade_keeps_package_scope() {
  command_exists() { return 0; }
  export -f command_exists
  local action=""
  npm() { action="$*"; }
  export -f npm
  pkg_set_mode upgrade
  require_npm "@colbymchenry/codegraph" "codegraph"
  unset -f command_exists npm
  assert_equals "install -g @colbymchenry/codegraph@latest" "$action"
}

test_require_npm_upgrade_replaces_pinned_version() {
  command_exists() { return 0; }
  export -f command_exists
  local action=""
  npm() { action="$*"; }
  export -f npm
  pkg_set_mode upgrade
  require_npm "pnpm@9.1.0" "pnpm"
  unset -f command_exists npm
  assert_equals "install -g pnpm@latest" "$action"
}

test_require_go_upgrades_to_latest() {
  command_exists() { return 0; }
  export -f command_exists
  local action=""
  go() { action="$*"; }
  export -f go
  pkg_set_mode upgrade
  require_go "github.com/example/tool/cmd/tool@v1.2.3"
  unset -f command_exists go
  assert_equals "install github.com/example/tool/cmd/tool@latest" "$action"
}

test_require_pip_upgrades_when_installed() {
  local action=""
  pip3() {
    if [[ "$1" == "show" ]]; then return 0; fi
    action="$*"
  }
  export -f pip3
  pkg_set_mode upgrade
  require_pip "somepkg"
  unset -f pip3
  assert_equals "install --user --upgrade somepkg" "$action"
}

test_require_pacman_upgrades_with_syu() {
  local action=""
  pacman() { return 0; }
  sudo() {
    shift
    action="$*"
  }
  export -f pacman sudo
  pkg_set_mode upgrade
  require_pacman "some-pkg"
  unset -f pacman sudo
  assert_equals "-Syu --noconfirm some-pkg" "$action"
}

test_require_gh_release_skips_installed_binary_in_install_mode() {
  command_exists() { return 0; }
  export -f command_exists
  local fetched=false
  curl() { fetched=true; }
  export -f curl
  require_gh_release "owner/repo" "somebin"
  unset -f command_exists curl
  assert_equals "false" "$fetched"
}

test_require_gh_release_refetches_in_upgrade_mode() {
  command_exists() { return 0; }
  export -f command_exists
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  local marker="$tmp/fetched"
  # curl runs inside a command substitution, so record the call in a file
  curl() { touch "$marker"; echo ""; }
  jq() { echo ""; }
  export -f curl jq
  pkg_set_mode upgrade
  # No tag_name comes back from the stub, so the fetch fails after being attempted
  assert_retval 1 require_gh_release "owner/repo" "somebin"
  unset -f command_exists curl jq
  assert_file_exists "$marker"
}

# ── artifact recording ──

test_pkg_record_is_a_noop_without_an_app() {
  _state_setup; trap _state_teardown RETURN
  pkg_set_app ""
  pkg_record brew "some-pkg"
  pkg_set_app "testapp"
  assert_equals "[]" "$(_artifacts)"
}

test_pkg_record_defaults_to_owned() {
  _state_setup; trap _state_teardown RETURN
  pkg_record brew "some-pkg"
  assert_equals "true" "$(_artifacts | jq -r '.[0].owned')"
}

test_require_brew_records_ownership_when_it_installs() {
  _state_setup; trap _state_teardown RETURN
  brew() {
    if [[ "$1" == "list" ]]; then return 1; fi
    return 0
  }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
  assert_equals '{"kind":"brew","id":"some-pkg","owned":true}' "$(_artifacts | jq -c '.[0]')"
}

test_require_brew_records_preexisting_package_as_unowned() {
  _state_setup; trap _state_teardown RETURN
  brew() { return 0; }
  export -f brew
  require_brew "some-pkg"
  unset -f brew
  assert_equals '{"kind":"brew","id":"some-pkg","owned":false}' "$(_artifacts | jq -c '.[0]')"
}

test_require_brew_cask_records_cask_kind() {
  _state_setup; trap _state_teardown RETURN
  brew() { return 0; }
  export -f brew
  require_brew_cask "some-cask"
  unset -f brew
  assert_equals "brew_cask" "$(_artifacts | jq -r '.[0].kind')"
}

test_require_npm_records_base_package_name() {
  _state_setup; trap _state_teardown RETURN
  command_exists() { return 1; }
  npm() { return 0; }
  export -f command_exists npm
  require_npm "pnpm@9.1.0" "pnpm"
  unset -f command_exists npm
  assert_equals '{"kind":"npm","id":"pnpm","owned":true}' "$(_artifacts | jq -c '.[0]')"
}

test_require_npm_records_scoped_package_name() {
  _state_setup; trap _state_teardown RETURN
  command_exists() { return 1; }
  npm() { return 0; }
  export -f command_exists npm
  require_npm "@colbymchenry/codegraph" "codegraph"
  unset -f command_exists npm
  assert_equals "@colbymchenry/codegraph" "$(_artifacts | jq -r '.[0].id')"
}

test_require_go_records_the_installed_binary_path() {
  _state_setup; trap _state_teardown RETURN
  local GOBIN="$_tmpdir/gobin"
  command_exists() { return 1; }
  go() { return 0; }
  export -f command_exists go
  require_go "github.com/example/tool/cmd/tool@v1.2.3"
  unset -f command_exists go
  assert_equals '{"kind":"path","id":"'"$GOBIN"'/tool","owned":true}' "$(_artifacts | jq -c '.[0]')"
}

test_require_script_records_nothing() {
  _state_setup; trap _state_teardown RETURN
  curl() { echo ':'; }
  export -f curl
  require_script "https://example.com/install.sh"
  unset -f curl
  assert_equals "[]" "$(_artifacts)"
}

# ── artifact removal ──

test_pkg_remove_artifact_uninstalls_brew_formula() {
  local action=""
  command_exists() { return 0; }
  brew() { action="$*"; }
  export -f command_exists brew
  pkg_remove_artifact brew "some-pkg"
  unset -f command_exists brew
  assert_equals "uninstall some-pkg" "$action"
}

test_pkg_remove_artifact_uninstalls_brew_cask() {
  local action=""
  command_exists() { return 0; }
  brew() { action="$*"; }
  export -f command_exists brew
  pkg_remove_artifact brew_cask "some-cask"
  unset -f command_exists brew
  assert_equals "uninstall --cask some-cask" "$action"
}

test_pkg_remove_artifact_skips_brew_when_brew_is_gone() {
  local action=""
  command_exists() { return 1; }
  brew() { action="$*"; }
  export -f command_exists brew
  pkg_remove_artifact brew "some-pkg"
  unset -f command_exists brew
  assert_equals "" "$action"
}

test_pkg_remove_artifact_removes_apt_package() {
  local action=""
  dpkg() { return 0; }
  sudo() { shift; action="$*"; }
  export -f dpkg sudo
  pkg_remove_artifact apt "some-pkg"
  unset -f dpkg sudo
  assert_equals "remove -y some-pkg" "$action"
}

test_pkg_remove_artifact_skips_apt_package_that_is_not_installed() {
  local action=""
  dpkg() { return 1; }
  sudo() { shift; action="$*"; }
  export -f dpkg sudo
  pkg_remove_artifact apt "some-pkg"
  unset -f dpkg sudo
  assert_equals "" "$action"
}

test_pkg_remove_artifact_removes_pacman_package() {
  local action=""
  pacman() { return 0; }
  sudo() { shift; action="$*"; }
  export -f pacman sudo
  pkg_remove_artifact pacman "some-pkg"
  unset -f pacman sudo
  assert_equals "-Rs --noconfirm some-pkg" "$action"
}

test_pkg_remove_artifact_uninstalls_npm_package() {
  local action=""
  npm() { action="$*"; }
  export -f npm
  pkg_remove_artifact npm "@scope/pkg"
  unset -f npm
  assert_equals "uninstall -g @scope/pkg" "$action"
}

test_pkg_remove_artifact_uninstalls_cargo_crate() {
  local action=""
  cargo() { action="$*"; }
  export -f cargo
  pkg_remove_artifact cargo "ripgrep"
  unset -f cargo
  assert_equals "uninstall ripgrep" "$action"
}

test_pkg_remove_artifact_uninstalls_pip_package() {
  local action=""
  pip3() { action="$*"; }
  export -f pip3
  pkg_remove_artifact pip "somepkg"
  unset -f pip3
  assert_equals "uninstall -y somepkg" "$action"
}

test_pkg_remove_artifact_removes_a_path() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  mkdir -p "$tmp/tree/nested"
  pkg_remove_artifact path "$tmp/tree"
  assert_not_exists "$tmp/tree"
}

test_pkg_remove_artifact_ignores_an_already_gone_path() {
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  assert_retval 0 pkg_remove_artifact path "$tmp/never-existed"
}

test_pkg_remove_artifact_refuses_a_relative_path() {
  assert_retval 1 pkg_remove_artifact path "some/relative/dir"
}

test_pkg_remove_artifact_refuses_an_empty_path() {
  assert_retval 1 pkg_remove_artifact path ""
}

test_pkg_remove_artifact_refuses_the_root_path() {
  assert_retval 1 pkg_remove_artifact path "/"
}

test_pkg_remove_artifact_removes_a_root_path_with_sudo() {
  local tmp action=""
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  mkdir -p "$tmp/tree"
  sudo() { action="$*"; }
  export -f sudo
  pkg_remove_artifact root_path "$tmp/tree"
  unset -f sudo
  assert_equals "rm -rf $tmp/tree" "$action"
}

test_pkg_remove_artifact_rejects_an_unknown_kind() {
  assert_retval 1 pkg_remove_artifact "telepathy" "some-pkg"
}

run_tests
