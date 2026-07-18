---
name: wezterm-helper
description: Answers questions about WezTerm (the GPU-accelerated terminal emulator) — config file structure, Lua config API, key bindings and leader keys, panes/tabs/windows/workspaces, multiplexing (unix/SSH/TLS domains), the wezterm CLI, and appearance customization. Use when the user asks how to configure, script, or troubleshoot WezTerm, or wants to know a key binding or action name.
metadata:
  domain: tooling
  triggers: wezterm, wezterm.lua, terminal emulator, leader key, mux domain, wezterm cli
  role: reference
  scope: qa
---

# WezTerm Helper

Reference for answering questions about WezTerm configuration and usage. WezTerm is configured entirely via a Lua file (`~/.config/wezterm/wezterm.lua` or `~/.wezterm.lua`) that returns a config table.

## Core mental model

- **Pane** — a single terminal instance (local process, SSH, or an overlay UI like Copy Mode).
- **Tab** — a container arranging one or more panes via splits.
- **Window** — the OS-level GUI window; shows one tab at a time plus the tab bar.
- **Workspace** — a named set of windows/tabs/panes, WezTerm's equivalent of a tmux "session." Switching workspaces swaps content in-place without opening a new OS window.
- **Domain** — where a pane's process actually runs: `local` (default, dies with the WezTerm process), `unix` (persistent, via `wezterm-mux-server`), `SSH` (remote, optionally multiplexed), `TLS` (encrypted remote mux over TCP).

## Quick answers

**Where's the config file?** Search order: `--config-file` flag → `$WEZTERM_CONFIG_FILE` → `$XDG_CONFIG_HOME/wezterm/wezterm.lua` → `~/.config/wezterm/wezterm.lua` → `~/.wezterm.lua`.

**Minimal config skeleton:**
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()  -- validates keys, gives friendly errors; prefer over local config = {}

config.color_scheme = 'Tokyo Night'
config.font = wezterm.font 'Berkeley Mono'
config.font_size = 13

return config
```

**Hot reload:** WezTerm watches the config file and reloads automatically on save. Manual reload is bound to `CTRL+SHIFT+R` (`act.ReloadConfiguration`) by default. Don't put unconditional side effects (spawning processes) at the top level — the file can be evaluated multiple times per process lifetime.

**Custom key binding pattern:**
```lua
local act = wezterm.action
config.keys = {
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
}
```

**Leader key:**
```lua
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
```
LEADER is a modal virtual modifier — press it, then within the timeout press a key bound with `mods = 'LEADER'` (or `LEADER|SHIFT` etc). WezTerm's own defaults don't use LEADER; it's opt-in for tmux-style workflows.

**Full default key binding list:** run `wezterm show-keys --lua` to dump the live defaults as copy-pasteable Lua, or see `references/wezterm-reference.md` in this skill for the common subset (splits, pane nav, tabs, copy mode, font size).

**Persistent sessions (survive closing the terminal):** unix domain.
```lua
config.unix_domains = { { name = 'unix' } }
config.default_gui_startup_args = { 'connect', 'unix' }
```
Attach with `wezterm connect unix`.

**Persistent sessions over SSH:** requires `wezterm` installed on the remote host.
```lua
config.ssh_domains = { { name = 'my.server', remote_address = '1.2.3.4', username = 'me' } }
```
Attach with `wezterm connect my.server`. Plain `wezterm ssh host` is just an SSH client session — no persistence.

**Scripting layouts from the shell:**
```
wezterm cli split-pane --right --percent 30
wezterm cli split-pane --bottom --percent 40 --cwd ~/dev/myproject
```

## When to load the reference file

Load `references/wezterm-reference.md` for: the full default-keybinding table, the `wezterm.action`/KeyAssignment category list (pane/tab/window/copy-mode/clipboard/scroll/workspace actions), appearance options (color schemes, fonts, tab bar, background image/opacity, status bar via `update-status`), `launch_menu`, the full `wezterm cli` subcommand list, and the event/callback system (`wezterm.on`, `format-tab-title`, `format-window-title`).

## Notes on staying current

WezTerm docs live at wezterm.org (recently moved from wezfurlong.org/wezterm — old links may redirect). The project ships continuous nightly-versioned docs rather than a single pinned release, so if the user reports behavior that doesn't match this reference, check `wezterm show-keys --lua` and `wezterm -V` against the live install before assuming the reference is right.
