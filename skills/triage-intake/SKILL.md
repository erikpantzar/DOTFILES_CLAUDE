---
name: triage-intake
description: Entry point for the triage pipeline. Takes a wide scope of work items — a Linear view/query/list of ids, GitHub issues, or just "this repo + this kind of task" — normalizes them, dispatches one triage-analyst agent per item to find the true intent, writes verdicts back to the source, and auto-hands fix-now briefs to triage-execute for draft PRs. Applies when the user says "triage these", "run triage on the feedback view", "go through these issues and fix what's fixable", or hands over a batch of mixed reports.
user-invocable: true
---

# Triage intake: wide scope in, briefs and draft PRs out

Pipeline: **normalize → cluster → analyze (parallel) → write back → execute →
report**. The analysis method lives in `triage-brief`; the implementation
hand-off lives in `triage-execute`; this skill is only the funnel and the
dispatcher. Default mode is full-auto: every `fix-now` brief proceeds to a
draft PR without asking — draft PRs are the review checkpoint, not chat.

Before anything else, check the current repo for its own triage/batch/branch
skills (`.claude/skills/`) and `CLAUDE.md` conventions — where a repo defines
its own workflow for a pipeline stage, the repo's version wins over the
generic instructions here.

## Step 1 — Establish source and scope

The invocation usually names the source. If it doesn't, ask ONE question up
front ("what am I triaging — a Linear view, GitHub issues, or a description
of the work?") and nothing else; every later decision comes from the briefs.

- **Linear**: ticket ids, a view ("the feedback view"), or a query. Fetch via
  `mcp__linear__list_issues` / `get_issue`. Oversized results land in a saved
  file — parse it with jq rather than reading it raw. Record each item's id,
  title, description, comments, labels, state.
- **GitHub issues**: `gh issue list` / `gh issue view --comments --json …`.
- **Ad-hoc**: pasted lists, Slack complaints, "look for flaky e2e tests in
  this repo". Write each item as a numbered entry in a scratch file so it has
  a stable id (`adhoc-1`, `adhoc-2`) for the rest of the pipeline.

Normalize everything to: `id, title, body, source, url, state`. This shape is
what analysts receive and what the final report is keyed by.

## Step 2 — Cluster before dispatching

Skim all items once, before any deep work:

- Obvious same-symptom items → one unit, analyzed together (the analyst
  confirms or refutes the duplication; don't pre-judge silently).
- Items that are clearly one epic in disguise → flag them for spec work
  instead of pushing them through this pipeline.
- Already-fixed/stale candidates stay in — cheap for an analyst to confirm,
  and "already fixed on the default branch" is a useful verdict to write
  back.

## Step 3 — Dispatch analysts in parallel

One `triage-analyst` agent per unit (background), each prompt containing the
full normalized item — analysts should not re-fetch what you already have,
except comments/links they choose to chase. Cap live concurrency at ~4-5 for
a big batch; analysts are read-only so they cannot collide, the cap is about
keeping results reviewable as they land.

Collect the briefs verbatim. If an analyst returns something that isn't a
parseable brief, re-dispatch that one item with the malformed output quoted —
don't hand-repair the brief yourself.

## Step 4 — Write verdicts back to the source

- **Linear** (full write is authorized): post the brief as a comment
  (`save_comment`), then apply the verdict via `save_issue` — duplicates get
  marked duplicate/canceled with a link to the canonical issue, `wont-fix`
  gets a closing comment + state change, `needs-spec`/`needs-info` get a
  label or comment stating exactly what's missing, `fix-now` moves to In
  Progress when execution starts. Set estimate from Size if the team uses
  estimates.
- **GitHub**: comment the brief; close duplicates/wont-fix with the
  justification.
- **Ad-hoc**: no write-back target — briefs live in the final report and the
  scratch file.

## Step 5 — Execute the fix-nows

Every `fix-now` brief goes to `triage-execute`, one agent per item, each in
its own git worktree so agents can never collide (the Agent tool's
`isolation: "worktree"`, or the repo's own worktree tooling if it has some).
Items whose briefs touch the same files are sequenced, not parallelized —
disjoint file sets are the precondition for running anything concurrently.

`needs-spec`, `needs-info`, `duplicate`, `wont-fix` never auto-execute. A
split brief (`<id>-a`, `<id>-b`) executes only its fix-now parts.

## Step 6 — Report

One table, the whole batch: `item | verdict | size | outcome`, where outcome
is a draft-PR link, the write-back performed, or the blocking question. Below
the table, only the items that need the user: needs-spec decisions and
needs-info questions, each in one sentence. The user reviews code in the
draft PRs, not here.
