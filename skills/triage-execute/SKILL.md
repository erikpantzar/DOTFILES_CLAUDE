---
name: triage-execute
description: Turn one accepted fix-now triage brief into a verified draft PR — worktree/branch per the repo's conventions, implement to the brief's success criteria, run the repo's verify gate, open the PR with the brief embedded, and update the source ticket. Applies when a triage brief has verdict fix-now, or the user says "execute this brief" / "ship the fix for the triaged ticket".
user-invocable: true
---

# Triage execute: brief → verified draft PR

Input is one triage brief with verdict `fix-now` (shape defined in
`triage-brief`). The brief is the work order: its **success criteria are the
definition of done**, and its root-cause analysis is trusted — re-verify the
cited `file:line` evidence still holds before coding (the codebase may have
moved since triage), but don't re-litigate the diagnosis. If the evidence
no longer holds, stop and send the item back through `triage-brief` instead
of improvising a new diagnosis mid-implementation.

Repo conventions win: if the repo has its own skills or `CLAUDE.md` rules for
branching, PR flow, or verification, follow those over the generic steps
below.

## Procedure

1. **Branch + worktree.** Use the repo's branch naming and PR-target
   conventions (check `CLAUDE.md`, recent PRs, and any branch-flow skill;
   don't assume the target is the default branch — some repos route PRs
   through sprint/epic branches). Branch from a freshly pulled parent. When
   running as part of a batch, always work in a dedicated worktree.

2. **Success criteria → checks first.** Any criterion phrased as behavior
   gets a failing test before the fix, in whatever test framework the repo
   already uses. Criteria that aren't testable (copy changes, visual tweaks)
   get a screenshot or manual-verification note instead. Write down which
   criterion maps to which check — it becomes the PR's verification section.

3. **Implement to the criteria and nothing else.** The brief already
   separated the true intent from the ticket's framing — resist re-reading
   the original ticket and "improving" scope. Every changed line traces to a
   success criterion; match the surrounding code's style.

4. **Verify.** Run the repo's verify gate — the lint/typecheck/build/test
   chain its `CLAUDE.md`, `package.json` scripts, or CI config defines —
   scoped to affected projects while iterating, full gate before opening the
   PR. All success-criteria checks must pass; if one can't be made to pass,
   the PR still goes up as draft with that criterion explicitly marked unmet
   in the body — a blocked draft PR with honest status beats silent stalling.

5. **Draft PR.** Body contains, in order:
   - the triage brief verbatim (collapsed in a `<details>` block),
   - decisions made during implementation and why,
   - verification: criterion → check → command to re-run it,
   - anything unmet or discovered out-of-scope (as candidate follow-ups, not
     silent extra commits).
   Commit only your own files with explicit pathspecs — never a bare
   `git commit` relying on a pre-staged index, which can sweep in another
   process's staged changes. No Claude/Anthropic attribution anywhere.

6. **Write back to the source.** Linear: move the issue to In Review, attach
   the PR link, comment any deviation from the brief. GitHub: comment the PR
   link on the issue. Ad-hoc: the PR link goes in the batch report.

## Out-of-scope discoveries

Implementation regularly surfaces adjacent problems the brief didn't cover.
Never fold them into the PR. File them (new tracker ticket or GitHub issue,
one line + file:line) or list them under follow-ups in the PR body — they are
tomorrow's triage-intake input, which is the loop working as intended.
