---
name: commit-tldr
model: haiku
effort: low
description: Given one or more commit hashes, get the date, author, and a tldr of what the commit actually did — fast, minimum tool calls. Use when Erik pastes a commit hash (short or full) and asks what it was, what changed, when it landed, or for a summary/tldr of a commit.
metadata:
  author: erik
  scope: personal
---

# Commit tldr

Fast commit lookup. One tool call per commit (batch hashes into one call when there are several) — no full diff, no extra grepping around the repo unless the message itself is useless.

## Workflow

1. Run exactly this, one command for all requested hashes (repeat `-1 <hash>` per hash, or loop in the shell — still one Bash call):

   ```
   git log -1 --stat --date=short --format='%H%n%an%n%ad%n%n%s%n%n%b%n---STAT---' <hash>
   ```

   For multiple hashes in one go:

   ```
   for h in <hash1> <hash2> ...; do git log -1 --stat --date=short --format='%H%n%an%n%ad%n%n%s%n%n%b%n---STAT---' "$h"; echo "===END==="; done
   ```

   `--stat` (via `git log`, not `git show`) gives the file-level diffstat without the full patch — that's what keeps this to one cheap call.

2. From that single output, write the tldr yourself:
   - **Date** — the `%ad` line, as-is (already short-form).
   - **Author** — the `%an` line.
   - **TLDR** — one or two sentences from the subject/body plus what the diffstat implies (which areas/files moved, roughly how much). Don't restate the commit message verbatim if it's already a good tldr — just relay it plus scope (files/lines touched).

3. **Only if the message is genuinely uninformative** (e.g. "wip", "fix", "asdf", or body is empty and subject is opaque) — fall back to one extra call: `git show --stat -p <hash> -- <the 1-2 files with the most churn>` to infer intent from the actual diff. Don't do this by default; it's the exception, not the norm.

4. If a hash doesn't resolve, say so plainly (bad hash / not in this repo) — don't guess or search history for a near-match unless asked.

## Output shape

Keep it tight, no preamble:

```
<short hash>  <date>  <author>
<tldr, 1-2 sentences>
<N files changed, +X/-Y> (only if it adds signal beyond the tldr)
```

Multiple hashes → one such block each, newest first if order isn't given.
