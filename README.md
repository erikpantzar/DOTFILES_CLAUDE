# DOTFILES_CLAUDE

Version-controlled configuration for [Claude Code](https://claude.ai/code) — the `~/.claude` directory — plus a shared `zshrc`, synced across macOS, Linux, and Windows machines via symlinks.

## What's tracked

| Path in repo | Symlinked to |
|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `skills/` | `~/.claude/skills/` |
| `zshrc` | `~/.zshrc` |

> `settings.json` is intentionally excluded — it contains machine-specific permissions and should be managed per-device.

`zshrc` sources `zsh-autosuggestions` and `zsh-syntax-highlighting` (in that order — syntax-highlighting must load last) via whatever `brew --prefix` resolves to, so it works unmodified on Intel Mac, Apple Silicon Mac, and Linuxbrew. On Linux without Homebrew it falls back to the apt package paths (`/usr/share/...`). Native Windows has no zsh — if you use zsh on Windows, do it through WSL and follow the Linux steps there instead of the PowerShell steps below.

## Setup

### 1. Clone the repo

```sh
git clone https://github.com/erikpantzar/DOTFILES_CLAUDE.git ~/dev/DOTFILES_CLAUDE
```

### 2. Symlink

#### macOS / Linux

```sh
cd ~/dev/DOTFILES_CLAUDE
./install.sh
```

`install.sh` iterates every file and directory in the repo root (skipping `.git`, `README.md`, `zshrc`, and itself), backs up anything already in `~/.claude/`, and creates symlinks. It then symlinks `zshrc` to `~/.zshrc`, and installs `zsh-autosuggestions`/`zsh-syntax-highlighting` via `brew` (or `apt` if no `brew`) if they're not already present. Re-running it is safe — existing symlinks are skipped.

Run `./install.sh --dry-run` first to preview what would be backed up, linked, and installed without changing anything.

---

#### Windows (PowerShell — run as Administrator)

No install script yet. Link manually:

```powershell
$repo = "$env:USERPROFILE\dev\DOTFILES_CLAUDE"
$claude = "$env:USERPROFILE\.claude"

# Back up existing files if present
if (Test-Path "$claude\CLAUDE.md") { Rename-Item "$claude\CLAUDE.md" "CLAUDE.md.bak" }
if (Test-Path "$claude\skills")    { Rename-Item "$claude\skills"    "skills.bak"    }

# Create symlinks (Junction for dirs — no Admin needed)
New-Item -ItemType SymbolicLink -Path "$claude\CLAUDE.md" -Target "$repo\CLAUDE.md"
New-Item -ItemType Junction     -Path "$claude\skills"    -Target "$repo\skills"
```

> `zshrc` is skipped here — native Windows/PowerShell has no zsh. If you use zsh on Windows via WSL, run the macOS/Linux steps above from inside the WSL shell instead.
>
> Add new entries as you add more tracked items to the repo.

---

## Verify

```sh
ls -la ~/.claude/
ls -la ~/.zshrc
```

Each tracked entry should show `->` pointing into your repo clone.

## Workflow

1. Edit files in `~/dev/DOTFILES_CLAUDE/`
2. Commit and push — changes are live immediately on the current machine via the symlink
3. On other machines: `git pull` to get updates
