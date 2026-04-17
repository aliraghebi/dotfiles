# Project Reference — dotfiles CLI

Personal dotfiles manager. Supports **macOS** and **Ubuntu/Linux** today; more
targets (Arch, Windows, ...) may land later — keep OS-specific logic behind
`lib/os.sh` so new OSes plug in cleanly. Cloned to `~/.dotfiles`; single CLI at
`bin/dotfiles`. The framework is stable — typical work is **adding apps**,
**adding features**, **fixing bugs**. `lib/` / `bin/` changes are fine when a
feature needs them; hold the clean-code bar and add tests for any `lib/` change.

---

## Commands

| Command | Behaviour |
|---|---|
| `dotfiles install <app>` | install dispatch → reconcile links → `config.sh` |
| `dotfiles config <app>`  | verify `APP_BINARY` → reconcile links → `config.sh` |
| `dotfiles remove <app>`  | unlink → revert backups → `remove.sh` |
| `dotfiles update`        | `git pull` only |
| `dotfiles list`          | all apps with OS tag + status |

---

## Per-app structure

```
apps/<n>/
  meta.sh       # required — metadata only, no side effects
  install.sh    # optional — install_brew / install_apt / install
  config.sh     # optional — post-link script
  remove.sh     # optional — post-unlink script
  config/       # optional — files symlinked into $HOME
```

### `meta.sh`

```bash
APP_OS="macos,linux"          # "macos" | "linux" | "macos,linux"
APP_BINARY="nvim"             # checked by `config`; "" skips check
APP_DESCRIPTION="Neovim"
APP_DEPS=("gpg")              # other apps installed first if missing
APP_CONFIGS=(
  "config/.config/nvim : ~/.config/nvim"
  "config/init-macos.lua : ~/.config/nvim/init-macos.lua : macos"
)

NVIM_PLUGIN_DIR="..."         # app-private vars — prefix with app name
```

- `APP_CONFIGS` entry: `"src : dst"` or `"src : dst : os_tag"`. `src` is
  relative to the app dir; `dst` supports `~`; `os_tag` is `macos` or `linux`.
- `APP_DEPS` prompts `[y/N/a]` per missing dep; `a` = yes-to-all; any `N` aborts.
  Each dep installs via the full `cmd_install` flow.
- Defaults if omitted: `APP_OS="macos,linux"`, `APP_BINARY=""`, `APP_TYPE=""`,
  `APP_DEPS=()`, `APP_CONFIGS=()`.
- `APP_TYPE="action"`: skips state, reconciliation, and `remove`; shows `~ Action` in `dotfiles list`. For one-shot apps with no managed links.
- `meta.sh` sets variables only — never runs commands, never has side effects.

### `install.sh` dispatch

1. `install_brew` defined + brew present → call; hard-fail on error.
2. else `install_apt` defined + apt present → call; hard-fail on error.
3. then `install` defined → call; hard-fail on error.
4. File exists but nothing ran → hard-fail.
5. File missing → skip silently (valid for config-only apps).

### `config.sh` / `remove.sh`

Plain scripts, no functions, no state writes. All `lib/*` helpers in scope.
Must be **idempotent** — re-runs are expected and must be safe.

---

## Reconciliation (runs on `install` and `config`)

1. Desired set = `APP_CONFIGS` filtered by current OS.
2. Current set = `links[]` in state.
3. Remove links not in desired → revert backup if present.
4. Create links new in desired → back up any pre-existing regular file.
5. Skip links already correct.

Each action writes state immediately — never batched.

---

## State file

- macOS: `$HOME/Library/Application Support/dotfiles/state.json`
- Linux: `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.json`

```json
{ "nvim": { "status": "configured", "configured_at": "...",
  "links": [ { "src": "...", "dst": "..." } ], "backups": [] } }
```

`status`: `configured` | `configuring` | `removing`.
Only `links` and `backups` are tracked — never `config.sh` outcomes, never
arbitrary data. **All reads/writes go through `lib/state.sh`.**

---

## Library surface (use these — do not re-implement)

| Module | Functions |
|---|---|
| `lib/log.sh`   | `info`, `ok`, `warn`, `error`, `step` |
| `lib/os.sh`    | `is_macos`, `is_linux`, `os_name`, `linux_distro`, `is_brew`, `is_apt`, `dotfiles_state_file` |
| `lib/utils.sh` | `command_exists`, `ensure_dir`, `download_file`, `add_line_to_file`, `is_ci` |
| `lib/link.sh`  | `safe_link`, `safe_unlink` |
| `lib/state.sh` | all state read/write (jq-based) |
| `lib/pkg.sh`   | `require_brew[_cask/_tap]`, `require_apt`, `require_cargo`, `require_go`, `require_pip`, `require_gh_release`, `require_script` (all idempotent) |

---

## Clean-code rules (enforced — review every change against this list)

**DRY — use the library, do not recreate it.**
- Package install? `require_*`. Never inline `brew install` / `apt-get install` / `curl | sh`.
- Symlink? `safe_link` / `safe_unlink`. Never raw `ln -s` or `rm`.
- Logging? `info` / `ok` / `warn` / `error` / `step`. Never raw `echo` with colors.
- OS check? `is_macos` / `is_linux` / `os_name`. Never re-parse `uname`.
- State? `lib/state.sh` only. Never `jq`, `grep`, `sed`, `awk` on `state.json` elsewhere.

**SRP — one job per unit.**
- `meta.sh` declares, never acts. `install.sh` installs packages, nothing else.
  `config.sh` configures, `remove.sh` cleans up what `config.sh` created.
- Library modules own their domain. Cross-module duplication is a bug — extend
  the owning module instead.

**YAGNI / no speculative abstraction.**
- No flags, hooks, or config knobs without a current caller. No "future-proof"
  parameters. Three similar lines beat a premature helper.
- No dead code, commented-out blocks, or `TODO` placeholders. Delete instead.

**Fail fast, fail loud.**
- `set -euo pipefail` on every script. Hard-fail on install errors — never
  swallow with `|| true` unless the value is explicitly optional (document why).
- Validate at boundaries (user input, external commands). Trust internal helpers.

**Idempotency is mandatory.**
- `install` / `config` / `remove` must be safely re-runnable. Check state before
  acting; mutate state immediately after acting.

**No hidden coupling.**
- App-private vars in `meta.sh` must be prefixed with the app name
  (`GOPASS_REPO`, not `REPO`).
- Apps never read another app's state, files, or vars. Cross-app dependencies
  go through `APP_DEPS` only.

**Comments explain *why*, not *what*.**
- Default to no comment. Add one only for non-obvious constraints, subtle
  invariants, or workarounds — never to restate the code.

---

## Coding standards

- `#!/usr/bin/env bash` on every script. **Bash 3.2 compatible** — no
  `declare -A`, `mapfile`, `readarray`, `${var,,}`.
- 2-space indent; `local` every function var; `[[ ]]` not `[ ]`; quote `"$var"`.
- Raw ANSI escapes for color — no `tput`. No `set -x` in shipped files.

---

## Testing — mandatory for every `lib/` change

Every new function or behaviour change in `lib/` needs a matching test before
the work is done. Tests live in `tests/test_<module>.sh` and run via
`bash tests/run_all.sh`.

- Framework: `tests/unit.sh` (defines `assert_equals`, `assert_retval`,
  `assert_contains`, `assert_file_exists`, `assert_symlink`, `assert_not_exists`,
  `run_tests`).
- Functions prefixed `test_` are auto-discovered. Use `_setup` / `_teardown`
  with `trap _teardown RETURN` for temp dirs.
- Isolate with `mktemp -d` — never write inside the repo.
- Stub `brew`, `apt-get`, `cargo`, `curl` via shell functions — no real package
  managers, no network, no sleeps.

---

## Adding a new app

1. `apps/<n>/meta.sh` — set `APP_OS`, `APP_BINARY`, `APP_DESCRIPTION`, `APP_CONFIGS`.
2. `install.sh` if a package must be installed (prefer `require_*`).
3. `config/` mirroring `$HOME` for files that symlink in.
4. `config.sh` / `remove.sh` only if post-link setup is needed.
5. Verify: `dotfiles install <n>` → `dotfiles config <n>` → `dotfiles remove <n>`,
   then `dotfiles list`.

---

## Known constraints

- No package uninstall — `remove` only unlinks.
- No `install all` or profiles.
- `update` is `git pull` only — no auto-reconfig.
- `bin/dotfiles` is always a symlink.
- `install.sh` uses `$SUDO_USER` to resolve the real home under sudo.
- Distro-level branching lives in `install.sh` — never in `meta.sh`.
