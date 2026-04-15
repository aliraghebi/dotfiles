# Project Reference — dotfiles CLI

Personal dotfiles manager for macOS and Ubuntu/Linux. The repo is cloned to
`~/.dotfiles` and provides a single CLI entry point at `bin/dotfiles`.

### Quick install

```bash
sudo bash -c "$(curl -sL https://github.com/aliraghebiii/dotfiles/raw/main/install.sh)" @ install
```

---

## What is already implemented

The entire framework is complete and working:

- `bin/dotfiles` — full CLI dispatcher for all five commands
- `lib/log.sh` — `info`, `ok`, `warn`, `error`, `step`
- `lib/os.sh` — `is_macos`, `is_linux`, `os_name`, `linux_distro`, `is_brew`, `is_apt`, `dotfiles_state_file`
- `lib/utils.sh` — `command_exists`, `ensure_dir`, `download_file`, `add_line_to_file`, `is_ci`
- `lib/pkg.sh` — all `require_*` helpers
- `lib/link.sh` — `safe_link`, `safe_unlink`
- `lib/state.sh` — all state read/write functions via `jq`
- `install.sh` — full bootstrap (installs deps, clones repo to ~/.dotfiles, symlinks CLI)
- `apps/git` — config-only example
- `apps/zsh` — full example with install + config
- `apps/tmux` — example with config.sh and remove.sh
- `apps/macos` — config-only with config.sh

New work is **adding apps** and **fixing bugs** in the framework.

---

## Commands

| Command | What it does |
|---|---|
| `dotfiles install <app>` | Run install dispatch → reconcile links → run config.sh |
| `dotfiles config <app>` | Reconcile links → run config.sh (verifies binary first) |
| `dotfiles remove <app>` | Remove links → revert backups → run remove.sh |
| `dotfiles update` | `git pull` only — user runs config manually after |
| `dotfiles list` | Show all apps with OS tag and configured status |

---

## Per-app structure

```
apps/<n>/
  meta.sh        # required — metadata and APP_CONFIGS array
  install.sh     # optional — install_brew(), install_apt(), install()
  config.sh      # optional — plain script, runs after auto-linking
  remove.sh      # optional — plain script, runs after auto-unlinking
  config/         # optional — config files to symlink into $HOME
```

### `meta.sh`

```bash
APP_OS="macos,linux"       # comma-separated: "macos" | "linux" | "macos,linux"
APP_BINARY="nvim"          # binary checked by dotfiles config (empty = no check)
APP_DESCRIPTION="Neovim"
APP_DEPS=("gpg")           # optional — binaries that must exist before install/config
APP_CONFIGS=(
  "config/.config/nvim : ~/.config/nvim"
  "config/init-macos.lua : ~/.config/nvim/init-macos.lua : macos"
  "config/init-linux.lua : ~/.config/nvim/init-linux.lua : linux"
)

NVIM_SOME_SETTING="value"  # app-specific variable — see below
```

**`APP_OS` values:** comma-separated list of OS names the app supports.
- `"macos,linux"` — runs on both (most apps)
- `"macos"` — macOS only
- `"linux"` — Linux only

**OS detection:** `os_name` returns `"macos"` or `"linux"`. Distro-level differences
handled inside `install.sh` only, never in `meta.sh`.

**`APP_DEPS` format:** array of app names (matching a `apps/<name>/` directory) that must be installed before `install` or `config` runs.
- Each dep is checked via `command_exists` against its `APP_BINARY`
- If a dep is missing, the user is prompted: `[y/N/a]` — yes, no, or yes-to-all
- Answering `a` (yes-to-all) skips further prompts and installs all remaining missing deps
- Declining any dep aborts the command
- Each dep is installed via `cmd_install "<dep>"` — the full dotfiles install flow
- Example: `APP_DEPS=("gpg" "curl")`

**`APP_CONFIGS` format:** `"src : dst"` or `"src : dst : os_tag"`
- `src` is relative to the app directory
- `dst` supports `~` expansion
- `os_tag` optional: `"macos"` or `"linux"` — absent means both OSes

**Safe defaults if omitted:**
- `APP_OS` → `"macos,linux"`
- `APP_BINARY` → `""` (no binary check)
- `APP_DEPS` → empty array (no dependency check)
- `APP_CONFIGS` → empty array

**App-specific variables:** `meta.sh` may also define variables used only by the app's
own `install.sh` / `config.sh` / `remove.sh`. These are **not** read by `bin/dotfiles`.
- Prefix with the app name: `GOPASS_REPO`, `NVIM_PLUGIN_DIR`, etc.
- Place them after a blank line, separated from the framework variables above.
- Example: `GOPASS_REPO="git@github.com:user/passwords"`

### `install.sh`

```bash
install_brew() { require_brew <pkg>; }
install_apt()  { require_apt <pkg>; }
install()      { ... }
```

Dispatch rules:
- `install_brew` defined + brew present → call it; hard-fail if errors
- else `install_apt` defined + apt present → call it; hard-fail if errors
- then `install` defined → call it; hard-fail if errors
- `install.sh` exists but nothing ran → hard-fail with error
- `install.sh` missing → silently skip (valid for config-only apps)

### `config.sh` and `remove.sh`

Plain scripts, no functions. All lib helpers are in scope. Always fully re-executed —
their outcomes are never written to state.

---

## Reconciliation logic

On every `install` or `config`, after the package install step:

1. Compute desired set from `APP_CONFIGS` filtered for current OS
2. Read current set from `links[]` in state
3. Remove links no longer in desired set → revert backup if one exists
4. Create links new in desired set → backup any existing regular file first
5. Skip links already correct

Each action is written to state immediately. Re-runs are safe.

---

## State file

- macOS: `$HOME/Library/Application Support/dotfiles/state.json`
- Linux: `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.json`

```json
{
  "nvim": {
    "status": "configured",
    "configured_at": "2026-04-13T10:00:00Z",
    "links": [
      { "src": "/home/ali/.dotfiles/apps/nvim/config/.config/nvim", "dst": "/home/ali/.config/nvim" }
    ],
    "backups": []
  }
}
```

Status values: `configured` | `configuring` | `removing`.

Rules:
- Written per action, never batched
- `config.sh` / `remove.sh` outcomes never tracked
- Custom data never written — only links and backups
- All operations go through `lib/state.sh` only

---

## `lib/pkg.sh` — require helpers

```bash
require_brew        <pkg>
require_brew_cask   <pkg>
require_brew_tap    <tap> <pkg>
require_apt         <pkg>
require_cargo       <crate>
require_go          <module>
require_pip         <pkg>
require_gh_release  <owner/repo> <binary_name> [asset_template]
require_script      <url>
```

Each checks if already installed before running (idempotent).

---

## Coding standards

- `#!/usr/bin/env bash` and `set -euo pipefail` on all scripts
- **Bash 3.2 compatible** — no `declare -A`, no `mapfile`, no `readarray`
- 2-space indent, `local` for all function variables
- `[[ ]]` not `[ ]`, always quote `"$var"`
- `jq` only for JSON — never awk/sed/grep on state file
- No `set -x` in any shipped file
- Raw ANSI escapes for colors — no tput

---

## Testing

All core library code in `lib/` **must** have corresponding tests in `tests/`.
Every new function or behaviour change requires a matching test before work is done.

### Test infrastructure

| File | Purpose |
|---|---|
| `tests/unit.sh` | Minimal bash unit-test framework |
| `tests/run_all.sh` | Runner — executes every `tests/test_*.sh` |
| `tests/test_utils.sh` | Tests for `lib/utils.sh` |
| `tests/test_log.sh` | Tests for `lib/log.sh` |
| `tests/test_os.sh` | Tests for `lib/os.sh` |
| `tests/test_link.sh` | Tests for `lib/link.sh` |
| `tests/test_state.sh` | Tests for `lib/state.sh` |

Run the full suite:

```bash
bash tests/run_all.sh
```

### Writing tests

1. Create `tests/test_<module>.sh` matching the lib file
2. Source the unit framework and the lib under test
3. Define functions prefixed with `test_` — auto-discovered
4. Use `_setup` / `_teardown` with `trap _teardown RETURN` for temp dirs
5. Call `run_tests` at the bottom

### Available assertions

| Function | What it checks |
|---|---|
| `assert_equals <expected> <actual>` | String equality |
| `assert_retval <code> <command...>` | Exit code |
| `assert_contains <haystack> <needle>` | Substring match |
| `assert_file_exists <path>` | File or dir exists |
| `assert_symlink <path>` | Path is a symlink |
| `assert_not_exists <path>` | Path does not exist |

### Test conventions

- Use `mktemp -d` for isolation — never write to the repo tree
- Stub external commands (brew, apt-get, cargo) via shell functions — never call real package managers
- No network calls, no sleeps
- Bash 3.2 compatible throughout

---

## Adding a new app — checklist

1. Create `apps/<n>/` directory
2. Write `meta.sh` — set `APP_OS`, `APP_BINARY`, `APP_DESCRIPTION`, `APP_CONFIGS`
3. Write `install.sh` if the app has a package to install
4. Add config files under `config/` mirroring `$HOME` structure
5. Write `config.sh` if post-link setup is needed
6. Write `remove.sh` if `config.sh` created things that need cleanup
7. Test: `dotfiles install <n>` → `dotfiles config <n>` → `dotfiles remove <n>`
8. Verify `dotfiles list` shows the app correctly

---

## Known constraints

- No package uninstall — `dotfiles remove` only removes config links
- No `dotfiles install all` or profiles
- `dotfiles update` only runs `git pull` — no auto-reconfig
- `bin/dotfiles` is always a symlink — never copied
- `install.sh` uses `$SUDO_USER` to resolve real user home under sudo
- Distro-level differences handled inside `install.sh` only