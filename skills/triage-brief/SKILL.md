---
name: triage-brief
description: The method for triaging a single work item — separating what a ticket says from what it actually needs, tracing the report to real code, and producing a triage brief with a verdict. Applies when asked to "triage this ticket/issue" or figure out "what's really going on with" a report, or whenever the triage-analyst agent investigates an item. Analysis only; implementation is triage-execute's job.
user-invocable: true
---

# Triage brief: find the true intent of one work item

The output of this skill is a **triage brief** (template at the bottom). The
input is one work item: a Linear ticket, a GitHub issue, or an ad-hoc report
("someone said export is broken"). The job is to answer two questions the
report itself usually gets wrong: *what does the reporter actually need?* and
*what is actually causing it?*

## The three lies of tickets

Every report is filtered through the reporter's mental model. Before trusting
any of it, check for the three standard distortions:

1. **Symptom filed as the problem.** "The save button doesn't work" is an
   observation, not a problem statement. The problem might be a failed
   request, a validation error swallowed by the UI, or a disabled state the
   user didn't notice. Treat the reported behavior as the *starting point* of
   the investigation, never its conclusion.
2. **Prescribed fix filed as the requirement.** "Add a retry button" often
   means "I lost my work and it made me angry." Implementing the prescription
   verbatim can ship the wrong feature. Recover the underlying need, then
   judge whether the prescribed fix is actually the right response — say so
   in the brief either way.
3. **Several problems filed as one.** If your investigation surfaces two
   independent root causes (or one bug plus one feature request), the brief
   must say "this is N items" and give each its own verdict. One ticket does
   not obligate one fix.

## Investigation procedure

1. **Read everything first.** Description, all comments, linked
   tickets/PRs, attached screenshots or logs. Comments frequently contain a
   better problem statement than the description — or a teammate's
   half-finished diagnosis worth verifying.
2. **Restate the ask in one sentence** before touching code: "the reporter
   needs X because Y." If you can't, the item is under-specified — that's
   evidence toward `needs-spec`, but investigate before concluding.
3. **Trace it to code.** Find the surface the report describes (grep for the
   UI copy, the error text, the endpoint), then follow it to the behavior in
   question. Every claim in your brief needs a `file:line` you actually read.
   Use `git log`/`git blame` on the suspect area — a recent change that
   matches the report's timeline is strong evidence; also check whether the
   problem is already fixed on the default branch.
4. **Distinguish root cause from trigger.** The line where it breaks is
   rarely the line that's wrong. Ask "why is this value/state possible here?"
   until the answer is a design decision, not another line of code.
5. **Check for duplicates and neighbors.** Search the tracker for the same
   symptom and the same root cause (they cluster differently). An existing
   open PR or a sibling ticket changes the verdict.
6. **Size it honestly.** Line counts, not file counts — a "one file" fix in
   a 4,000-line component is not small; `wc -l` the suspect files before
   calling anything S. S = one sitting, mechanical once understood. M = a
   day-scale change, still one surface. L = multiple surfaces or needs
   design decisions.

## Verdicts

Exactly one per item (or one per sub-item after a split):

- `fix-now` — root cause located, success criteria are verifiable, no product
  decision needed. **The bar:** if you can't write success criteria a
  machine or reviewer could check, it is not fix-now.
- `needs-spec` — real, but requires a product/design decision the reporter
  didn't make (or the prescribed fix is wrong and the right one needs
  sign-off).
- `duplicate` — cite the canonical item.
- `wont-fix` — working as intended, or cost clearly exceeds value; justify.
- `needs-info` — could not locate/reproduce; state the exact question or
  artifact (log, repro steps, sample file) that would unblock.

## Brief template

Return exactly this shape — the orchestrator parses it:

```markdown
## Triage: <item id> — <original title>

**True intent:** <one sentence: what the reporter actually needs and why>
**Reported vs. actual:** <how the ticket's framing differs from what you found; "matches" if it doesn't>
**Root cause:** <the defective decision/code, with file:line evidence> <!-- omit for needs-spec/duplicate/wont-fix where N/A -->
**Evidence:** <bullet list of file:line + one-line finding each>
**Verdict:** fix-now | needs-spec | duplicate | wont-fix | needs-info
**Success criteria:** <numbered, each independently checkable> <!-- required for fix-now -->
**Size:** S | M | L — <one-line justification>
**Risks / notes:** <adjacent breakage, open questions, related items>
```

For a split, repeat the whole block per sub-item with ids like
`<item id>-a`, `<item id>-b`.
