---
name: stash-and-remind
model: haiku
effort: low
description: Park in-progress/exploratory work (docs, research, WIP) on its own branch instead of leaving it loose on the current branch, and put a real reminder on Erik's local macOS Calendar to come back and review it. Use when Erik says things like "stash this away", "park this on a branch", "save this for later and remind me", or asks for a branch plus a calendar reminder/invite for reviewing some work.
metadata:
  author: erik
  scope: personal
---

# Stash and remind

Erik's personal workflow for shelving work-in-progress without losing it or forgetting to revisit it. This is a personal convention, not a team one — don't add this skill to a project's own `.claude/skills/` (that gets committed and shared); it lives in the personal skills dir instead.

## Workflow

1. **Scope the files.** Only stash files that actually belong to the topic Erik named. Run `git status` and pick files by content relevance, not just "everything untracked" — leave unrelated untracked/WIP files (other docs, `.env`, lockfiles, config) alone on the original branch. If it's ambiguous which untracked files belong, ask rather than guessing broadly.

2. **Branch and commit.**
   - Create a new branch named for the topic (kebab-case, descriptive — e.g. `e2e-research-and-testing`).
   - `git add` only the scoped files, write a commit message describing what the work is (not "WIP" or "stash"), commit.
   - Switch back to the branch Erik was on before, so his working tree isn't left pointed at the new branch.

3. **Write the calendar event as an `.ics` file.**
   - Commit the `.ics` alongside the docs on the new branch (keeps a durable copy in the branch history, matching this repo's existing pattern of `docs/*-review.ics` files).
   - `SUMMARY`: "Review: <topic> (branch <branch-name>)".
   - `DESCRIPTION`: a real summary — what's on the branch, the headline recommendations/decisions, why it was parked rather than merged, and a next-steps checklist. Escape commas as `\,` and newlines as `\n` per RFC 5545 (see any existing `docs/*.ics` file in the repo for the exact format).
   - `DTSTART`/`DTEND`: use the date/time Erik specifies. If he only names a day ("Monday"), default to 10:00–10:30 local and confirm the resolved date against today's actual weekday — don't assume which date "Monday" maps to.

4. **Actually add it to his calendar — don't just leave the file.** Leaving an `.ics` in the repo isn't enough; Erik has to be told to go find and open it, which is exactly what this skill exists to avoid. Instead:
   - Get the `.ics` content onto disk outside the repo (e.g. scratchpad dir) — if the file only exists on the new branch and Erik isn't checked out there, use `git show <branch>:<path> > /path/to/scratchpad/event.ics`.
   - Run `open /path/to/scratchpad/event.ics`. On macOS this launches Calendar.app with an import prompt; it is not silent — Erik still confirms the add in the dialog, which is the right amount of confirmation for writing to his personal calendar.
   - After running `open`, ask Erik to confirm the import actually landed (don't assume success just because the command exited 0).

## Notes

- This skill does not push branches or open PRs — stashing is local-only until Erik separately asks to push/PR it.
- If Erik asks to "stash it away" again for a *different* piece of work, repeat the whole flow from scratch each time — don't try to append to a previous stash branch or reuse a previous calendar event.
