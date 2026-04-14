# CLAUDE.md — dotfiles CLI

Personal dotfiles manager for macOS and Ubuntu/Linux. The repo is cloned to
`~/.dotfiles` and provides a single CLI entry point at `bin/dotfiles`.

### Quick install

```bash
sudo bash -c "$(curl -sL https://github.com/aliraghebiii/dotfiles/raw/main/install.sh)" @ install
```

This runs `install.sh` which auto-installs prerequisites (git, curl, jq), clones
the repo to `~/.dotfiles`, and symlinks the CLI binary to `~/.local/bin/dotfiles`.
After bootstrap you can optionally pass a command (e.g. `install <app>`) which is
forwarded to the CLI automatically.

---

## What is already implemented

The entire framework is complete and working:

- `bin/dotfiles` — full CLI dispatcher for all five commands
- `lib/log.sh` — `info`, `ok`, `warn`, `error`, `step`
- `lib/os.sh` — `is_macos`, `is_linux`, `os_name`, `linux_distro`, `is_brew`, `is_apt`,
  `dotfiles_state_file`
- `lib/utils.sh` — `command_exists`, `ensure_dir`, `download_file`, `add_line_to_file`,
  `is_ci`
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
  meta.sh        # required — metadata and CONFIGS array
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

CONFIGS=(
  "config/.config/nvim : ~/.config/nvim"
  "config/init-macos.lua : ~/.config/nvim/init-macos.lua : macos"
  "config/init-linux.lua : ~/.config/nvim/init-linux.lua : linux"
)
```

**`APP_OS` values:** comma-separated list of OS names the app supports.
- `"macos,linux"` — runs on both (most apps)
- `"macos"` — macOS only (e.g. `aerospace`, `macos`)
- `"linux"` — Linux only (e.g. `udev`, `sway`)

The CLI checks whether the current OS appears in the comma-separated list. No magic
keyword like `"both"` — just list what you support.

**OS detection:** `os_name` returns `"macos"` or `"linux"`. Distro-level differences
(Ubuntu vs Arch) are handled inside `install.sh` functions, never in `meta.sh`.

**`CONFIGS` format:** `"src : dst"` or `"src : dst : os_tag"`
- `src` is relative to the app directory
- `dst` supports `~` expansion
- `os_tag` is optional: `"macos"` or `"linux"` — absent means both OSes

Most apps will have the same config files on all OSes. Per-OS config entries in `CONFIGS`
are only needed when the destination path differs (e.g. `~/Library/...` on macOS) or
when the config file itself has OS-specific content.

**Safe defaults if omitted:**
- `APP_OS` → `"macos,linux"`
- `APP_BINARY` → `""` (no binary check)
- `CONFIGS` → empty array

### `install.sh`

```bash
install_brew() { require_brew <pkg>; }   # called when brew exists on system
install_apt()  { require_apt <pkg>; }    # called when apt-get exists on system
install()      { ... }                   # always called after package manager step
```

All three are optional. Define only what applies.

Dispatch rules:
- `install_brew` defined + brew present → call it; hard-fail if it errors
- else `install_apt` defined + apt present → call it; hard-fail if it errors
- then `install` defined → call it; hard-fail if it errors
- `install.sh` exists but nothing ran → hard-fail with error
- `install.sh` missing → silently skip (valid for config-only apps)

Distro-specific logic (e.g. Ubuntu vs Arch) belongs inside `install_apt` or additional
functions — never in `meta.sh`.

### `config.sh` and `remove.sh`

Plain scripts, no functions. All lib helpers are in scope. Always fully re-executed on
every call — their outcomes are never written to state.

---

## Reconciliation logic

On every `install` or `config`, after the package install step:

1. Compute desired set from `CONFIGS` filtered for current OS
2. Read current set from `links[]` in state
3. Remove links no longer in desired set → revert backup if one exists
4. Create links new in desired set → backup any existing regular file first
5. Skip links already correct

Each action is written to state immediately. Re-runs are safe and continue from partial
state.

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

Status values: `configured` | `configuring` | `removing`. The `removing` status means
`dotfiles remove` was interrupted — `dotfiles list` shows it as `incomplete` and suggests
re-running `dotfiles remove <app>`.

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
require_gh_release  <owner/repo> <binary_name>
require_script      <url>
```

Each checks if already installed before running (idempotent). Returns non-zero on
failure — callers let `set -e` propagate.

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

All core library code lives in `lib/` and **must** have corresponding tests in
`tests/`. Every new function or behaviour change in a `lib/*.sh` file requires a
matching test before the work is considered done.

### Test infrastructure

| File | Purpose |
|---|---|
| `tests/unit.sh` | Minimal bash unit-test framework (assertions + auto-discovery) |
| `tests/run_all.sh` | Runner — executes every `tests/test_*.sh` and reports results |
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

1. Create `tests/test_<module>.sh` matching the lib file (e.g. `lib/pkg.sh` →
   `tests/test_pkg.sh`)
2. Source the unit framework and the lib under test:
   ```bash
   source "$TESTS_DIR/unit.sh"
   source "$DOTFILES_DIR/lib/pkg.sh"
   ```
3. Define functions prefixed with `test_` — the framework auto-discovers them
4. Use `_setup` / `_teardown` with `trap _teardown RETURN` for temp dirs
5. Call `run_tests` at the bottom of the file

### Available assertions

| Function | What it checks |
|---|---|
| `assert_equals <expected> <actual>` | String equality |
| `assert_retval <code> <command...>` | Exit code of a command |
| `assert_contains <haystack> <needle>` | Substring match |
| `assert_file_exists <path>` | File or dir exists |
| `assert_symlink <path>` | Path is a symlink |
| `assert_not_exists <path>` | Path does not exist |

### What must be tested

Every implementation in the core libraries needs proper tests. Specifically:

- **`lib/link.sh`** — `safe_link`, `safe_unlink`, backup creation, parent-dir creation
- **`lib/state.sh`** — state read/write, status transitions, link/backup tracking
- **`lib/os.sh`** — OS detection, distro detection, state-file path resolution
- **`lib/utils.sh`** — `command_exists`, `ensure_dir`, `add_line_to_file`, `is_ci`
- **`lib/log.sh`** — output formatting for `info`, `ok`, `warn`, `error`, `step`
- **`lib/pkg.sh`** — `require_brew`, `require_apt`, `require_cargo`, `require_go`,
  `require_pip`, `require_gh_release`, `require_script` (stub the actual install
  commands and verify the logic around them)

When adding a new `require_*` helper or any new function to a core lib, **add
tests in the same PR**. A change without tests is incomplete.

### Test conventions

- Use `mktemp -d` for isolation — never write to the repo tree
- Stub external commands (brew, apt-get, cargo) by defining shell functions in
  the test that shadow them — never call real package managers in tests
- Keep tests fast — no network calls, no sleeps
- Follow Bash 3.2 compatibility (same as the rest of the project)

---

## Adding a new app — checklist

1. Create `apps/<n>/` directory
2. Write `meta.sh` — set `APP_OS`, `APP_BINARY`, `APP_DESCRIPTION`, `CONFIGS`
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
- Config-only apps leave `APP_BINARY` empty to skip the binary check in `dotfiles config`
- `bin/dotfiles` is always a symlink — never copied — so `git pull` takes effect on next
  invocation without reinstalling
- `install.sh` uses `$SUDO_USER` to resolve the real user's home directory when run
  via `sudo` — this ensures the repo is cloned and symlinks are created in the correct
  home, not `/root`
- Distro-level differences (Ubuntu vs Arch) are handled inside `install.sh` only, never
  in `meta.sh` or `CONFIGS`