# dotfiles

A personal dotfiles manager for macOS and Linux. Installs, configures, and removes per-app configs via symlinks — with a clean CLI, dependency resolution, and safe backup/restore.

## Quick start

```bash
# Remote install (bootstraps everything)
sudo bash -c "$(curl -sL https://github.com/aliraghebiii/dotfiles/raw/main/install.sh)"

# Or, if you already have the repo cloned
bash install.sh
```

The installer will:
1. Install prerequisites (`git`, `curl`, `jq`)
2. Clone the repo to `~/.dotfiles`
3. Symlink the CLI to `~/.local/bin/dotfiles`

Make sure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## CLI usage

```
dotfiles <command> [app]

  install <app>   Install and configure an app
  config  <app>   Configure an app (must already be installed)
  remove  <app>   Remove an app's config links
  update          Pull latest dotfiles from git
  list            List all apps and their status
```

### Examples

```bash
dotfiles list              # see all apps and their status
dotfiles install neovim    # install + symlink config
dotfiles config zsh        # re-apply config links for zsh
dotfiles remove kitty      # remove symlinks, restore any backups
dotfiles update            # git pull latest
```

## Apps

| App | Platform | Description |
|---|---|---|
| brew | macOS | Homebrew package manager |
| btop | macOS, Linux | Resource monitor — CPU, memory, disks, network, processes |
| chrome | macOS, Linux | Google Chrome web browser |
| docker | macOS, Linux | Docker container platform |
| fonts | macOS, Linux | System fonts — JetBrains Mono, Fira Code, Nerd Fonts, Vazirmatn |
| git | macOS, Linux | Git version control |
| go | macOS, Linux | Go programming language and toolchain |
| gopass | macOS, Linux | Password manager backed by git |
| gpg | macOS, Linux | GNU Privacy Guard |
| k9s | macOS, Linux | Kubernetes CLI dashboard |
| keys | macOS, Linux | Add SSH public keys from GitHub to authorized_keys |
| kitty | macOS | GPU-accelerated terminal emulator |
| macos | macOS | macOS system defaults |
| neovide | macOS | GPU-accelerated GUI frontend for Neovim |
| neovim | macOS, Linux | Hyperextensible Vim-based text editor |
| slack | macOS | Slack desktop application |
| starship | macOS, Linux | Cross-shell prompt |
| tmux | macOS, Linux | Terminal multiplexer |
| vim | macOS, Linux | Vi IMproved text editor |
| wakatime | macOS, Linux | WakaTime coding activity tracker |
| zsh | macOS, Linux | Z shell |

## How it works

Each app lives under `apps/<name>/` and can have:

- `meta.sh` — metadata: name, binary, OS support, config file mappings, dependencies
- `install.sh` — package install (via `brew`, `apt`, `pacman`, or a custom function)
- `config.sh` — post-link setup script (idempotent)
- `remove.sh` — cleanup script run on `dotfiles remove`
- `config/` — files that get symlinked into `$HOME`

On `install` or `config`, the manager reconciles symlinks: it creates new links, removes stale ones, and backs up any files that were in the way. On `remove`, it unlinks everything and restores those backups.

State is tracked in a JSON file:
- macOS: `~/Library/Application Support/dotfiles/state.json`
- Linux: `~/.local/state/dotfiles/state.json`

## Adding a new app

```
apps/<name>/
  meta.sh        # required
  install.sh     # optional
  config.sh      # optional
  remove.sh      # optional
  config/        # optional — mirrors $HOME structure
```

Minimal `meta.sh`:

```bash
APP_OS="macos,linux"
APP_BINARY="mytool"
APP_DESCRIPTION="My tool"
APP_CONFIGS=(
  "config/.config/mytool : ~/.config/mytool"
)
```

Then verify:

```bash
dotfiles install <name>
dotfiles config  <name>
dotfiles remove  <name>
dotfiles list
```
