# WezTerm Detailed Reference

Canonical docs: https://wezterm.org (moved from wezfurlong.org/wezterm — old links redirect). WezTerm ships continuously-versioned nightly docs, not a single pinned release; verify surprising details against `wezterm show-keys --lua` and `wezterm -V` on the live install.

## 1. Config file location, structure, hot-reload

Search order:
1. `--config-file` CLI argument
2. `$WEZTERM_CONFIG_FILE` env var
3. (Windows "thumb drive" mode) `wezterm.lua` next to `wezterm.exe`
4. `$XDG_CONFIG_HOME/wezterm/wezterm.lua` (if set)
5. `$HOME/.config/wezterm/wezterm.lua`
6. `$HOME/.wezterm.lua` (fallback)

A config file is a Lua script that must `return` a config table:
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.initial_cols = 120
config.initial_rows = 28
config.font_size = 10
config.color_scheme = 'AdventureTime'
return config
```

`wezterm.config_builder()` returns validating userdata (typo'd keys warn/error with a stack trace) instead of a plain table — prefer it over `local config = {}`.

Modular config: Lua's `require()` searches `~/.config/wezterm`, `~/.wezterm`, and system paths, so `require 'keys'` loads `keys.lua` alongside `wezterm.lua`.

Hot reload: WezTerm watches the file and reloads most options automatically on save (GPU/font-rasterizer changes may need a restart). Manual reload: `CTRL+SHIFT+R` / `SUPER+R` (`act.ReloadConfiguration`). The file may be evaluated multiple times per process lifetime — avoid unconditional side effects (e.g. spawning background processes) at the top level.

CLI overrides (persist across reloads):
```
wezterm --config enable_scroll_bar=true
wezterm --config 'exit_behavior="Hold"'
```

## 2. Leader key and custom key bindings

```lua
local wezterm = require 'wezterm'
local act = wezterm.action  -- conventional alias
local config = wezterm.config_builder()

config.keys = {
  { key = 'm', mods = 'CMD', action = act.DisableDefaultAssignment },
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
}
return config
```

- Key spec prefixes: `phys:` (physical key position), `mapped:` (post-keyboard-layout character, the default for unprefixed keys, controlled by `key_map_preference`), `raw:` (raw hardware key code, e.g. `"raw:123"`).
- Modifiers combine with `|`: `CTRL`, `SHIFT`, `ALT`/`OPT`/`META`, `SUPER`/`CMD`/`WIN`, and the special `LEADER`.
- `config.disable_default_key_bindings = true` wipes all built-ins.

**Leader key** — a modal virtual modifier: press the leader combo, it becomes active; only `LEADER`-tagged bindings fire; auto-cancels on any keypress or timeout.
```lua
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
  { key = '"', mods = 'LEADER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
}
```
`timeout_milliseconds` defaults to 1000. WezTerm's own defaults don't use LEADER — it's purely opt-in (popular tmux-style choice: `CTRL-a`).

Remapped Caps Lock as leader on X11 (`setxkbmap -option caps:none`):
```lua
config.leader = { key = 'VoidSymbol', mods = '', timeout_milliseconds = 1000 }
```

**Key tables** (`config.key_tables`) — named binding sets layered onto a per-window stack via `act.ActivateKeyTable { name = ..., one_shot = ..., timeout_milliseconds = ..., replace_current = ... }`, with `act.PopKeyTable` / `act.ClearKeyTableStack` to manage it. Used for modal workflows like a tmux-style resize mode. Copy Mode and Search Mode are themselves built-in key tables (`copy_mode`, `search_mode`) you can override/extend.

## 3. Default key bindings (common subset)

Authoritative live dump: `wezterm show-keys --lua`. Mac uses `CMD` where Linux/Windows use `CTRL+SHIFT` (often both bound).

**Splitting:** `CTRL+SHIFT+ALT+"` split vertical, `CTRL+SHIFT+ALT+%` split horizontal.

**Pane navigation:** `CTRL+SHIFT+<Arrow>` activate pane in direction; `CTRL+SHIFT+ALT+<Arrow>` resize; `CTRL+SHIFT+Z` toggle pane zoom.

**Tabs:** `CTRL+SHIFT+T`/`SUPER+T` new tab; `SUPER+SHIFT+T` new tab in default domain; `CTRL+SHIFT+W`/`SUPER+W` close tab (confirms); `CTRL+SHIFT+1..9`/`SUPER+1..9` activate tab N (9 = last); `CTRL+SHIFT+TAB`/`SUPER+SHIFT+[` previous tab; `CTRL+TAB`/`SUPER+SHIFT+]` next tab; `CTRL+SHIFT+PageUp/PageDown` move tab.

**Copy/search/select:** `CTRL+SHIFT+X` Copy Mode; `CTRL+SHIFT+F`/`SUPER+F` Search mode; `CTRL+SHIFT+Space` QuickSelect; `CTRL+SHIFT+U` CharSelect; `CTRL+SHIFT+P` Command Palette.

**Font size:** `CTRL/SUPER + -` decrease, `+ =` increase, `+ 0` reset.

**Other:** `CTRL+SHIFT+N`/`SUPER+N` new window; `ALT+ENTER` toggle fullscreen; `CTRL+SHIFT+K` clear scrollback; `CTRL+SHIFT+R`/`SUPER+R` reload config; `CTRL+SHIFT+C`/`SUPER+C` copy; `CTRL+SHIFT+V`/`SUPER+V` paste; `CTRL+INSERT` copy to primary selection; `SHIFT+INSERT` paste primary selection.

Override an individual default by adding a `config.keys` entry with matching `key`/`mods`; wipe all defaults with `config.disable_default_key_bindings = true`.

## 4. Panes/tabs/windows/workspaces hierarchy

- **Pane** — terminal instance (local, remote, or overlay UI). Fundamental split unit.
- **Tab** — arranges panes in a split layout; `tab.panes` in Lua gives the pane array.
- **Window** — OS-level GUI window; shows one Tab plus the tab bar.
- **Workspace** — named independent collection of windows/tabs/panes (tmux "session" equivalent). `act.SwitchToWorkspace { name = 'monitoring', spawn = { args = { 'top' } } }` creates-or-switches; `act.SwitchWorkspaceRelative { offset = 1 }` cycles. No `name` given to `SwitchToWorkspace` → new randomly-named workspace.

Internals: a singleton Mux owns MuxWindows → each owns Tabs → each manages a Pane tree (encodes split layout).

## 5. Multiplexing domains

**Local** — implicit default, drives native OS windows directly, dies with the process.

**Unix domain** — persistent session via `wezterm-mux-server` over a Unix socket:
```lua
config.unix_domains = { { name = 'unix' } }
config.default_gui_startup_args = { 'connect', 'unix' }
```
Connect: `wezterm connect unix`. Fields: `socket_path`, `no_serve_automatically`, `skip_permissions_check` (WSL/NTFS), `proxy_command`, `local_echo_threshold_ms`.

**SSH domain** — multiplexed session over SSH, requires `wezterm` on the remote host (unlike plain `wezterm ssh`, a non-persistent regular SSH client session):
```lua
config.ssh_domains = {
  { name = 'my.server', remote_address = '192.168.1.1', username = 'wez', multiplexing = 'None', assume_shell = 'Posix' },
}
```
Connect: `wezterm connect my.server`. Auto-populates from `~/.ssh/config`: each host gets `SSH:hostname` (plain) and `SSHMUX:hostname` (multiplexed) entries.

**TLS domain** — encrypted remote mux over TCP:
```lua
-- client
config.tls_clients = { { name = 'server.name', remote_address = 'server.hostname:8080', bootstrap_via_ssh = 'server.hostname' } }
-- server
config.tls_servers = { { bind_address = 'server.hostname:8080' } }
```
Connect: `wezterm connect server.name`.

`wezterm-mux-server` is the daemon hosting a persistent session; auto-spawned on demand (clients run `wezterm cli --prefer-mux proxy` remotely), or run explicitly with `--daemonize`.

## 6. wezterm.action (KeyAssignment) categories

Convention: `local act = wezterm.action`. Full index: `config/lua/keyassignment/index.html`.

- **Pane:** `SplitHorizontal`, `SplitVertical`, `SplitPane`, `ActivatePaneDirection { direction = "Up"|"Down"|"Left"|"Right" }`, `ActivatePaneByIndex`, `PaneSelect`, `CloseCurrentPane { confirm = true }`, `AdjustPaneSize`, `RotatePanes`, `TogglePaneZoomState`/`SetPaneZoomState`.
- **Tab:** `SpawnTab 'CurrentPaneDomain'`, `ActivateTab { index = 0 }`, `ActivateTabRelative { offset = 1 }`, `ActivateTabRelativeNoWrap`, `ActivateLastTab`, `CloseCurrentTab { confirm = true }`, `MoveTab`, `MoveTabRelative`, `ShowTabNavigator`.
- **Window:** `SpawnWindow`, `ActivateWindow`, `ActivateWindowRelative`, `ToggleFullScreen`, `SetWindowLevel`, `ToggleAlwaysOnTop`, `StartWindowDrag`.
- **Copy/search/select:** `ActivateCopyMode`, `Search { CaseSensitiveString = "foo" }` (also `CaseInSensitiveString`, `Regex`), `QuickSelect`, `QuickSelectArgs { patterns = {...}, action = ... }`, `CharSelect`, `CompleteSelection`, `SelectTextAtMouseCursor`, `ExtendSelectionToMouseCursor`.
- **Clipboard:** `Copy`, `CopyTo 'Clipboard'`, `Paste`, `PasteFrom 'Clipboard'`, `PastePrimarySelection`.
- **Font:** `IncreaseFontSize`, `DecreaseFontSize`, `ResetFontSize`, `ResetFontAndWindowSize`.
- **Scroll:** `ScrollByLine`, `ScrollByPage`, `ScrollToTop`, `ScrollToBottom`, `ScrollToPrompt`, `ScrollByCurrentEventWheelDelta`.
- **Workspace/domain:** `SwitchToWorkspace { name = ... }`, `SwitchWorkspaceRelative { offset = 1 }`, `AttachDomain 'name'`, `DetachDomain`.
- **Misc:** `SendKey`, `SendString "text"`, `EmitEvent 'my-event'`, `QuitApplication`, `ReloadConfiguration`, `ResetTerminal`, `ShowLauncher`, `ShowLauncherArgs { flags = "FUZZY|TABS" }`, `ActivateCommandPalette`, `InputSelector`, `DisableDefaultAssignment`.

## 7. Common customizations

**Color scheme** (700+ built-in):
```lua
config.color_scheme = 'Tokyo Night'
```
Mutually exclusive with manual `config.colors = { ... }` (named CSS colors, hex, HSL, `rgb()`/`hsl()`; `ansi`/`brights` for 16 base colors; `cursor_bg`/`cursor_fg`/`cursor_border`; `selection_fg`/`selection_bg`; `indexed` for palette 16-255).

**Fonts:**
```lua
config.font = wezterm.font('Berkeley Mono')
config.font_size = 13
```
`wezterm.font_with_fallback({...})` for fallback chains; both accept weight/style attributes.

**Tab bar:**
```lua
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.colors = {
  tab_bar = {
    background = '#0b0022',
    active_tab = { bg_color = '#2b2042', fg_color = '#c0c0c0' },
    inactive_tab = { bg_color = '#1b1032', fg_color = '#808080' },
  },
}
```
Fancy tab bar (default) themed via `window_frame` instead. `format-tab-title` event gives full programmatic control.

**Status bar** — no dedicated config block; hook `update-status`:
```lua
wezterm.on('update-status', function(window, pane)
  window:set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Text = wezterm.strftime '%Y-%m-%d %H:%M:%S' },
  })
end)
```
`config.status_update_interval` controls frequency (ms).

**Background/opacity:**
```lua
config.window_background_image = '/path/to/wallpaper.jpg'
config.window_background_image_hsb = { brightness = 0.3, hue = 1.0, saturation = 1.0 }
config.window_background_opacity = 0.9
config.text_background_opacity = 1.0
config.window_background_gradient = { colors = { '#0f0c29', '#302b63' }, orientation = 'Vertical' }
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.8 }
```

**launch_menu** (entries shown via the "+" button or `ShowLauncher`):
```lua
config.launch_menu = {
  { args = { 'top' } },
  { label = 'Bash', args = { 'bash', '-l' } },
  { label = 'Project shell', args = { 'zsh' }, cwd = '/Users/erik/dev/myproject' },
}
```
Each entry is a `SpawnCommand`: `label`, `args`, `cwd`, `set_environment_variables`.

## 8. wezterm CLI subcommands

Top-level: `wezterm start` (default GUI launch), `wezterm ssh <host>` (plain SSH, no mux persistence), `wezterm connect <domain>` (attach GUI to a configured unix/SSH/TLS domain), `wezterm serial`, `wezterm cli ...`, `wezterm record`/`wezterm replay`, `wezterm imgcat <file>`, `wezterm ls-fonts`, `wezterm show-keys` (`--lua` for copy-pasteable output).

`wezterm cli` (needs a running GUI/mux instance):
- `list` — windows/tabs/panes with IDs
- `list-clients` — connected mux clients
- `split-pane [--left|--right|--top|--bottom] [--percent N] [--cwd DIR] [--top-level] [--move-pane-id ID] [PROG...]` — split, prints new pane-id
- `spawn [--domain-name NAME] [--cwd DIR] [PROG...]` — new tab/window with a command
- `send-text` — send text/keystrokes into a pane
- `move-pane-to-new-tab` — pull a pane into its own tab
- `activate-pane` / `activate-pane-direction` — focus by id / direction
- `activate-tab` — focus a tab
- `kill-pane` — close a pane
- `set-tab-title` / `set-window-title` — rename
- `adjust-pane-size` — resize
- `get-text` — dump pane content
- `zoom-pane` — zoom/unzoom
- `rename-workspace` — rename current workspace

Example scripted layout:
```
wezterm cli split-pane --right --percent 30
wezterm cli split-pane --bottom --percent 40 --cwd ~/dev/myproject
```

## 9. Event/callback system

`wezterm.on(event_name, callback)` registers at config-load time (top level, not inside another callback).

**update-status** (periodic, interval = `config.status_update_interval`) — populate left/right status via `window:set_left_status()`/`set_right_status()`. Some community examples use the older name `update-right-status`; canonical current name is `update-status`.

**format-tab-title** (synchronous, must return fast):
```lua
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab.tab_title
  if not title or #title == 0 then title = tab.active_pane.title end
  if tab.is_active then
    return { { Background = { Color = 'blue' } }, { Text = ' ' .. title .. ' ' } }
  end
  return title
end)
```

**format-window-title** — analogous, for the native OS window title.

Other events: `gui-startup` (once at GUI launch — good for programmatic initial layout/workspace setup), `window-config-reloaded`, `bell`, `mux-startup`, pane-content lifecycle hooks. Config must still `return config` after registering handlers as a side effect.

## Source pages
- config/files.html, config/lua/wezterm/config_builder.html, config/keys.html, config/default-keys.html, config/key-tables.html, config/lua/keyassignment/index.html, multiplexing.html, config/lua/SshDomain.html, config/appearance.html, config/lua/config/launch_menu.html, config/launch.html, cli/cli/index.html, cli/cli/split-pane.html, config/lua/keyassignment/SwitchToWorkspace.html, recipes/workspaces.html, config/lua/window-events/update-status.html, config/lua/window-events/format-tab-title.html, config/lua/window-events/format-window-title.html, config/lua/config/index.html — all under https://wezterm.org/
