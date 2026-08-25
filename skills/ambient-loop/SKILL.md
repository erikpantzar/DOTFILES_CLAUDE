---
name: ambient-loop
description: Turn any bit of context (Linear tickets, GitHub PRs on a branch, git log, a file, any command output) into a looping terminal animation via `tte` (terminaltexteffects) — a fun ambient/idle screen for a spare pane, not a status dashboard. Use when the user asks to "loop this in a pane", "make this into a screensaver/animation", "run this through decrypt/matrix", or wants a personal ambient display of tickets/PRs/logs.
metadata:
  author: erik.pantzar@teneo.ai
  version: "1.0.0"
  domain: personal-tooling
  triggers: tte, terminaltexteffects, decrypt, matrix effect, ambient loop, screensaver, idle animation, loop tickets, loop PRs
  scope: personal
  output-format: shell
---

# Ambient Loop

Fetch some content, save it to a `.txt` file, and loop it through a `tte`
(terminaltexteffects) animation until the user hits Ctrl+C. Purely for fun —
an idle/ambient visual, not a live dashboard.

## Prerequisites

Check `tte` is installed before doing anything else:

```
which tte || echo "MISSING"
```

If missing, install via pipx (do NOT use plain `pip3 install` — Homebrew
Python blocks global installs with an externally-managed-environment error):

```
brew install pipx   # if pipx itself is missing
pipx install terminaltexteffects
```

## Step 1 — Figure out the content source

Ask the user (if not already clear from their request) what to animate. This
is genuinely open-ended — anything that can be turned into text is fair game:

- Linear tickets (by assignee, project, query, "unassigned", etc — use the
  `mcp__linear__list_issues` tool)
- GitHub PRs on a branch/repo (`gh pr list --json number,title,url ...`)
- `git log` on a branch
- Contents of an existing file
- Output of literally any shell command the user names
- ASCII art / banners — generated via `figlet` (big text banners, many fonts:
  `figlet -f <font> "text"`, list fonts with `figlet -I 2` or `showfigfonts`)
  or `cowsay` (talking-ASCII-art figures, many built in: `cowsay -l` lists
  them, `cowsay -f <figure> "message"`). Install both via
  `brew install figlet cowsay` if missing.

Don't overthink the source — just run whatever fetches the right data.

## Step 2 — Save content to a `.txt` file

Save to `~/.claude/tte-content/<name>.txt`, one item per line in a scannable
format, e.g.:

```
TX-1850 - User Feedback: Agent transfer to flow is not seamless
```

or for PRs:

```
#1234 - Fix flaky auth test (by erikpantzar)
```

Pick `<name>` from context (`tickets.txt`, `prs-main.txt`, `standup.txt`,
whatever fits). This directory is the fixed personal home for all ambient-loop
content files — reuse an existing file by name if the user is asking to
"refresh" rather than start a new one.

## Step 3 — Loop it through `tte`

Default effect: ask which one if unclear, otherwise `decrypt` is the safe
default (readable, not too busy). Other good ones: `matrix`, `beams`,
`bouncyballs`, `rain`. `tte --help` lists all of them.

Base loop pattern (re-reads the file every pass, so edits/re-fetches show up
on the next cycle — NOT live/hot-reload, just picked up next loop iteration):

```
while true; do clear; cat ~/.claude/tte-content/<name>.txt | tte <effect>; sleep 2; done
```

### Rotating through multiple distinct pieces

For "different pictures/things" style requests (e.g. a rotation of ASCII art
pieces rather than one static file), save each piece as its own file under
`~/.claude/tte-content/<name>-rotation/*.txt` and loop over the directory
instead of a single file:

```
while true; do for f in ~/.claude/tte-content/<name>-rotation/*.txt; do clear; cat "$f" | tte <effect>; sleep 2; done; done
```

### Color / style options

Every `tte` effect takes its own flags — check with `tte <effect> --help`.
Common ones worth knowing:

- `--final-gradient-stops <hex-or-xterm...>` — color(s) of the resolved text
- Effect-specific gradient flags, e.g. `matrix`'s `--rain-color-gradient`,
  `--highlight-color`
- Speed/timing flags vary per effect (e.g. `matrix --rain-time`,
  `decrypt --typing-speed`)

Only reach for these if the user asks for a specific look — don't over-tune
by default.

**User preference: avoid the matrix-green look.** `decrypt`'s default
`--ciphertext-colors` is green (`008000`) — that's the scrambling-phase color,
separate from `--final-gradient-stops` (the resolved-text color). Both need
to be set to actually get rid of the green. Default to white/bright yellow:

```
tte decrypt --ciphertext-colors ffffff ffff00 --final-gradient-stops ffff00 ffffff
```

## Step 4 — Run it in a tmux pane (if requested)

If the user wants it running in a specific tmux pane rather than the current
shell:

```
tmux list-sessions -F '#{session_name}'
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'
```

Confirm the exact pane target with the user if there's any ambiguity (e.g.
multiple panes with the same index in different windows) — don't guess.

Send the loop command with `tmux send-keys`, quoting the session name if it
contains spaces:

```
tmux send-keys -t '<session>:<window>.<pane>' "clear; while true; do clear; cat ~/.claude/tte-content/<name>.txt | tte <effect>; sleep 2; done" Enter
```

Verify it's actually running with `tmux capture-pane -t '<target>' -p | tail -20`
after a couple seconds — the capture will show scrambled/mid-animation text,
that's expected, not an error.

To stop a running loop before starting a new one in the same pane:

```
tmux send-keys -t '<target>' C-c
```

## Refreshing content

This skill does static fetch + manual refresh — there's no background
auto-refresh loop. To update the content shown by an already-running
animation loop: re-run the Step 1/2 fetch and overwrite the same
`~/.claude/tte-content/<name>.txt` file. The next iteration of the `while`
loop (every ~2s + animation time) will `cat` the new content automatically —
no need to restart the loop itself.
