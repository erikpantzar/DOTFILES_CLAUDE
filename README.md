# DOTFILES_CLAUDE

Version-controlled configuration for [Claude Code](https://claude.ai/code) — the `~/.claude` directory — shared across macOS, Linux, and Windows machines via symlinks.

## What's tracked

| Path in repo | Symlinked to |
|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `skills/` | `~/.claude/skills/` |
| `-/` | `~/.claude/-/` |

> `settings.json` is intentionally excluded — it contains machine-specific permissions and should be managed per-device.

## Setup

### 1. Clone the repo

```sh
git clone https://github.com/YOUR_USERNAME/DOTFILES_CLAUDE.git ~/dev/DOTFILES_CLAUDE
```

### 2. Symlink

Pick the instructions for your OS.

---

#### macOS / Linux

```sh
REPO=~/dev/DOTFILES_CLAUDE

# Back up existing files if present
[ -f ~/.claude/CLAUDE.md ] && mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak
[ -d ~/.claude/skills ]    && mv ~/.claude/skills    ~/.claude/skills.bak
[ -d ~/.claude/- ]         && mv ~/.claude/-         ~/.claude/-.bak

# Create symlinks
ln -s "$REPO/CLAUDE.md" ~/.claude/CLAUDE.md
ln -s "$REPO/skills"    ~/.claude/skills
ln -s "$REPO/-"         ~/.claude/-
```

---

#### Windows (PowerShell — run as Administrator)

```powershell
$repo = "$env:USERPROFILE\dev\DOTFILES_CLAUDE"
$claude = "$env:USERPROFILE\.claude"

# Back up existing files if present
if (Test-Path "$claude\CLAUDE.md") { Rename-Item "$claude\CLAUDE.md" "CLAUDE.md.bak" }
if (Test-Path "$claude\skills")    { Rename-Item "$claude\skills"    "skills.bak"    }
if (Test-Path "$claude\-")         { Rename-Item "$claude\-"         "-.bak"         }

# Create symlinks
New-Item -ItemType SymbolicLink -Path "$claude\CLAUDE.md" -Target "$repo\CLAUDE.md"
New-Item -ItemType Junction     -Path "$claude\skills"    -Target "$repo\skills"
New-Item -ItemType Junction     -Path "$claude\-"         -Target "$repo\-"
```

> On Windows, directory symlinks require either Administrator privileges or Developer Mode enabled. Junctions work without either and are preferred for directories.

---

## Verify

```sh
ls -la ~/.claude/CLAUDE.md ~/.claude/skills ~/.claude/-
```

Each entry should show `->` pointing into your repo clone.

## Workflow

1. Edit files in `~/dev/DOTFILES_CLAUDE/`
2. Commit and push — changes are live immediately on the current machine via the symlink
3. On other machines: `git pull` to get updates
