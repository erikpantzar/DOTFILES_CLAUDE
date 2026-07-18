# Neovim Navigation & Editing — Detailed Reference

Sourced from official Neovim docs (`neovim.io/doc`, `runtime/doc/*.txt`) and community references.

## 1. Modes

| Mode | Enter from Normal | Exit to Normal |
|---|---|---|
| Normal | default; `<Esc>` from anywhere | — |
| Insert | `i` before cursor, `a` after cursor, `I` start of line, `A` end of line, `o` new line below, `O` new line above | `<Esc>` / `Ctrl-c` |
| Visual charwise | `v` | `<Esc>` or `v` again |
| Visual linewise | `V` | `<Esc>` or `V` again |
| Visual blockwise | `Ctrl-v` | `<Esc>` or `Ctrl-v` again |
| Command-line | `:`, `/`, `?` | `<CR>` execute, `<Esc>` cancel |
| Replace | `R` overtype, `gR` virtual replace | `<Esc>` |
| Terminal | `i`/`a` from Normal inside a terminal buffer | `Ctrl-\ Ctrl-n` (`<Esc>` is passed to the terminal instead) |

`v`/`V`/`Ctrl-v` toggle back to Normal on repeat; pressing a *different* visual key switches selection type in place.

## 2. Core motions

**Left-right:** `h j k l`, each takes `[count]`.

**Word motions** (word = alnum/`_` run or punctuation run; WORD = any non-blank run):
`w` next word start (excl.), `W` next WORD start, `b` prev word start (excl.), `B` prev WORD start, `e` next word end (incl.), `E` next WORD end, `ge` prev word end (incl.), `gE` prev WORD end.

**Line motions:** `0` col 0 (excl.), `^` first non-blank (excl.), `$` end of line (incl.; `3$` → end of line 2 down), `g_` last non-blank (incl.), `g0`/`g$` screen-line-aware (with `wrap`).

**File motions:** `gg` first line/`[count]`, `G` last line/`[count]`, `{n}G` e.g. `42G`, `{n}%` jump to percentage through file.

**Char search:** `f{c}` to next occurrence (incl., lands on it), `F{c}` to previous (excl.), `t{c}` till just before next (incl.), `T{c}` till just after previous (excl.), `;` repeat forward, `,` repeat reverse.

**Pattern search:** `/pattern<CR>` forward, `?pattern<CR>` backward, `n` repeat same direction, `N` repeat opposite.

**Paragraph/sentence:** `{`/`}` back/forward paragraph (blank-line separated), `(`/`)` back/forward sentence (`.`/`!`/`?` + whitespace).

**Matching:** `%` jump to matching `()`/`[]`/`{}` (also C comment delimiters, `#if`/`#else`/`#endif`).

**Scrolling:** `Ctrl-d`/`Ctrl-u` half-screen down/up (moves cursor), `Ctrl-f`/`Ctrl-b` full page, `Ctrl-e`/`Ctrl-y` scroll one line without moving cursor, `zz` center current line, `zt` current line to top, `zb` current line to bottom (`z-` variant moves to first non-blank).

**Marks:** `m{a-z}` local mark, `m{A-Z}` global (cross-file) mark, `` `{mark} `` exact position, `'{mark}` first non-blank of mark's line, `` `` ``/`''` back to position before last jump, `` `. ``/`'.` location of last change, `` `^ `` position where insert mode was last exited.

## 3. Operators + text objects

Grammar: `[count1] operator [count2] motion-or-textobject`. Counts multiply (`2d3w` = delete 6 words).

**Operators:** `d` delete, `c` change, `y` yank, `g~` swap case, `gu` lowercase, `gU` uppercase, `>`/`<` indent, `gq`/`gw` format, `!` filter through external command. Doubled = linewise: `dd cc yy >> gUU/guu`.

**Motion vs text object:** a motion goes from cursor to wherever it lands (`dw` may leave trailing whitespace or stop mid-word); a text object always covers the whole logical unit regardless of cursor position (`daw` deletes the whole word + surrounding space).

**Text objects** (`i` = inner/exclude delimiters, `a` = a/include delimiters):
`iw`/`aw` word, `iW`/`aW` WORD, `ip`/`ap` paragraph (+trailing blank line), `is`/`as` sentence, `i"` `a"` `i'` `a'` `` i`/a` `` quotes, `ib`/`i(` `ab`/`a(` parens, `iB`/`i{` `aB`/`a{` braces, `i[`/`a[` brackets, `it`/`at` HTML/XML tag pair (`dit` clears innerHTML, `dat` deletes whole tag+contents).

**Examples:** `daw` delete a word + trailing space, `ci"` change contents inside quotes, `yap` yank paragraph + trailing blank, `d}` delete to paragraph end (motion, stops exactly at boundary), `>ip` indent current paragraph, `gUiw` uppercase word under cursor.

**Dot-repeat (`.`):** repeats the last change (not pure motions), including a whole insert-mode session. `ciwFoo<Esc>` then `.` elsewhere repeats "change inner word to Foo". One of the highest-leverage habits.

**Forcing motion type:** typing `v`/`V`/`Ctrl-v` after an operator, before the motion, overrides its default charwise/linewise/blockwise-ness — e.g. `dvj` forces normally-linewise `j` to behave charwise.

## 4. Registers, yank/paste, macros

**Paste:** `p` after cursor/line, `P` before.

**Registers** (prefix with `"` + letter before the operator/paste, e.g. `"ayy`, `"ap`):
- Unnamed `""` — default target for all yank/delete/change; what plain `p` uses.
- Named `"a`-`"z` — 26 slots; lowercase overwrites, uppercase (`"A`) appends.
- Numbered `"0`-`"9` — `"0` always holds the last yank (untouched by deletes), `"1`-`"9` rotating delete/change history (`"1` most recent).
- Black hole `"_` — writes vanish, reads return nothing; use `"_d`/`"_daw` for throwaway deletes so a prior yank survives for pasting.
- System clipboard `"+`, primary selection `"*` (X11 middle-click).
- Special: `":` last command, `".` last inserted text, `"%` current filename, `"/` last search pattern.

**Macros:** `q{a-z}` start recording, `q` stop, `@{a-z}` play once, `{n}@{a-z}` play N times, `@@` repeat last macro. Macro contents live in a normal register — paste with `"ap` to edit/fix, re-yank with `"ayy` or `y$`.

## 5. Window management

`:split`/`:sp` (`Ctrl-w s`) horizontal split; `:vsplit`/`:vs` (`Ctrl-w v`) vertical split; `:split {file}`/`:vsplit {file}` split + open file.

Navigate: `Ctrl-w h/j/k/l` move by direction, `Ctrl-w w` cycle next, `Ctrl-w p` previous window, `Ctrl-w t`/`Ctrl-w b` top-left/bottom-right window.

Resize: `Ctrl-w =` equalize, `Ctrl-w +`/`-` taller/shorter, `Ctrl-w >`/`<` wider/narrower, `Ctrl-w _` maximize height, `Ctrl-w |` maximize width, `:resize N` explicit.

Close: `Ctrl-w c`/`:close` close window (buffer stays open elsewhere), `Ctrl-w q`/`:quit` quit window, `Ctrl-w o`/`:only` close all others.

Rearrange: `Ctrl-w r` rotate, `Ctrl-w x` swap with next, `Ctrl-w H/J/K/L` move current window to far edge.

## 6. Buffers and tabs

Distinction: **buffer** = in-memory file content; **window** = viewport onto a buffer; **tab page** = a saved window arrangement, not "one file" — the same buffer can appear in multiple windows across multiple tabs.

Buffers: `:ls`/`:buffers`/`:files` list, `:bnext`/`:bn` and `:bprevious`/`:bp` cycle, `:buffer {N}`/`:b {N}`/`:b {name}` jump, `:bdelete`/`:bd` remove from list, `Ctrl-^`/`Ctrl-6` toggle alternate file.

Tabs: `:tabnew`/`:tabnew {file}` new tab, `:tabclose` close, `:tabonly` close others, `gt`/`Ctrl-PageDown` next (wraps), `gT`/`Ctrl-PageUp` previous, `{n}gt` e.g. `2gt` jump to tab N, `:tabmove [N]` reorder, `:tabs` list.

Practical guidance: many experienced users rely mainly on buffers + splits, using tabs sparingly (e.g. one per project area) since tabs are heavier-weight than buffer switching.

## 7. Search & replace

`/pattern<CR>`/`?pattern<CR>` forward/backward, `n`/`N` repeat. `:s/old/new/` first match on current line, `:s/old/new/g` all matches on line, `:%s/old/new/g` whole file, `:%s/old/new/gc` with confirm (`y`/`n`/`a`/`q`/`l`/`^E`/`^Y` prompts). Ranges: `:5,10s/old/new/g`, `:'<,'>s/old/new/g` on visual selection. Very magic mode `\v` — regex metachars work unescaped: `:%s/\v(foo|bar)/baz/g` instead of `:%s/\(foo\|bar\)/baz/g`.

## 8. Jump list, change list, related navigation

Jump list tracks cursor position across "big" motions (searches, `G`, `%`, marks — not plain hjkl): `Ctrl-o` older position, `Ctrl-i`/`Tab` newer, `:jumps` view list, prefix with count to jump multiple steps.

Change list tracks edit locations: `g;` older change, `g,` newer change, `:changes` view list.

`` `` ``/`''` jump to position before last jump. `gd` local declaration (text-based, not LSP unless remapped), `gD` global declaration, `gf` open file under cursor, `K` look up keyword via `'keywordprg'` (default `man`; often remapped to LSP hover).

## 9. Beginner pitfalls and high-value habits

**Pitfalls:** arrow keys / staying off home row; excessive `jjjjj`/`hhhh` instead of a count or search; living in Insert mode and fixing mistakes with backspace/arrows instead of Normal-mode operators; manually visual-selecting text a text object could target directly; retyping an edit instead of using `.`; not using counts (`3dd`, `5j`) with relative line numbers; forgetting the black hole register and clobbering the yank register with intervening deletes; reaching for broad `:%s` when a local `ciw` + `.` walk is faster/safer.

**Habits:** text object before visual mode; make `.` part of the default editing loop; relative line numbers + counted motions instead of counting visually; `f`/`t`/`;`/`,` for intra-line jumps; jump list (`Ctrl-o`/`Ctrl-i`) instead of manual scrolling; drill `ci"`, `di(`, `dap`, `dit` as reflexes; use marks for quick teleport points during a session.

## 10. Optional plugins (not required for core navigation)

- **telescope.nvim** — fuzzy finder framework (files, live grep, buffers, git status, help tags) via an interactive picker; for jumping to a file/location you don't have open yet, complementing rather than replacing built-in motions/marks/jumps.
- **which-key.nvim** — shows available keybindings as you type a prefix key; a discoverability aid for custom/plugin mappings, doesn't change built-in Vim motions.

Everything in sections 1-9 works in stock Neovim with zero plugins.
