---
name: worktree-cleanup
description: Remove finished git worktrees whose branch is already up as a pull request, and delete local branches whose PR is merged. Use when Erik says "clean up my worktrees", "kill the inactive worktrees", "prune worktrees", "remove worktrees that are done", or asks what worktrees are lying around.
metadata:
  author: erik.pantzar@teneo.ai
  version: "1.0.0"
  scope: personal
  triggers: clean up worktrees, kill worktrees, prune worktrees, remove worktrees, worktree list, git worktree cleanup
---

# Worktree cleanup

Erik accumulates worktrees per ticket. Once the branch is up as a PR the directory
is dead weight — the work lives on the remote. This removes those and reports
what it left behind.

## The rule

**Branch has an open or merged PR → remove the worktree. No further checks.**

The PR is the safety net. Don't ask, don't hedge, don't check for running
processes — if it's up as a PR, the work is safe.

Two exceptions, both hard stops:

- **Dirty working tree** (`git status --porcelain` non-empty) → never remove.
  List it with the file count and move on.
- **The main checkout** (`/Users/epa/dev/teneo-x` and equivalents) → never remove.

Everything else — no PR, detached HEAD, unpushed commits — is left alone and
reported, not removed.

## Branches

After removing a worktree, delete its **local** branch only if its PR is
**merged**. Open PR → keep the branch. Never delete remote branches, ever.

## Procedure

1. Snapshot the state:

```bash
cd <repo root>
gh pr list --state all --limit 400 --json headRefName,number,state,isDraft \
  --jq '.[] | [.headRefName, .number, .state] | @tsv' > /tmp/prs.tsv
git worktree list --porcelain | awk '/^worktree /{wt=$2} /^branch /{print wt"\t"$2} /^detached/{print wt"\tDETACHED"}'
```

   `--state all` matters: merged PRs are the ones that also free a branch.
   Ignore CLOSED PRs — treat those branches as "no PR".

2. For each worktree, classify:

```bash
dirty=$(git -C "$wt" status --porcelain | wc -l)
```

   | Condition | Action |
   |---|---|
   | main checkout | skip |
   | dirty > 0 | skip, flag with file count |
   | detached HEAD | skip, flag |
   | branch PR OPEN | **remove worktree**, keep branch |
   | branch PR MERGED | **remove worktree + delete local branch** |
   | no PR / closed PR | skip, flag |

3. Remove, then prune:

```bash
git worktree remove "$wt"        # add --force ONLY for a merged-PR worktree
git worktree prune
git branch -d <branch>           # merged PRs only; -d not -D, let it refuse
```

   `git worktree remove` can fail on leftover build artifacts (`node_modules`,
   `bin/`, `.next`). For a **merged**-PR worktree, retry with `--force`.
   For an **open**-PR worktree, don't force — report the failure instead.

   `git branch -d` refusing to delete is a real signal: the branch has commits
   not in the target. Report it, never escalate to `-D`.

4. Report a table: what was removed (path, branch, PR) and what was skipped with
   the reason. Erik reads the skipped list — that's where his next decision is.

## Nice to have

Also worth mentioning in the report, but never acting on:

- Worktrees under `.claude/worktrees/` from agent runs that outlived their agent.
- Branches with no worktree and no PR at all.
