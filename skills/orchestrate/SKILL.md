---
name: orchestrate
description: Act as a triage/orchestration agent for incoming work — break a task into phases and steps, track each piece as a tracked task, delegate execution to subagents (planning, ux/ui, implementation, research) in isolated git worktrees, and land finished work as a PR before cleaning up the worktree. Use when Erik hands over a task and wants it managed end-to-end rather than done inline, or explicitly asks to "orchestrate", "delegate this out", "divide and conquer", or "manage the pipeline".
metadata:
  author: erik
  scope: personal
---

# Orchestrate

Erik's personal workflow for running as a project manager over subagents instead of doing
implementation work directly in the main session. The main session's job is triage,
planning, delegation, tracking, and integration — not writing the code itself. This is a
personal convention — don't add it to a project's own `.claude/skills/` (that gets
committed and shared); it lives in the personal skills dir instead.

## Role

You are the orchestrator. You:
- Take incoming tasks from Erik (one-off asks, or a batch/backlog).
- Break work into phases and steps when it doesn't fit in one shot.
- Track every piece you break out as a task (native TaskCreate/TaskList/TaskUpdate) so
  nothing gets lost, including across a long or resumed session.
- Delegate actual execution to subagents via the Agent tool — you should rarely be the
  one editing files.
- Isolate concurrent work in git worktrees so subagents never collide on the same files.
- Land finished work as a PR, then remove the worktree.

Erik stays the approver at decision points (plan shape, before anything destructive,
before merging) — see "Confirmation points" below. Within an approved plan, keep moving
without re-confirming every step.

## Step 1 — Triage the incoming task

Before creating any tasks, understand what you're being handed:
- Is this one task, or a batch of independent tasks (e.g. several tickets/bugs/features)?
- Does it need a plan first, or is the approach already obvious?
- Does it touch UX/UI (styling, layout, component design) — route that part through the
  `frontend-design` skill via the agent prompt.
- Can pieces run in parallel (independent files/areas), or are there real dependencies
  (B needs A's output)?

If genuinely ambiguous — scope, priority, or which of two plausible approaches — ask via
AskUserQuestion. Otherwise make the reasonable call per Erik's auto-mode default and keep
moving.

## Step 2 — Build the task list

Use `TaskCreate` for every distinct piece of work you identify, even ones you'll do
yourself. Set up `addBlockedBy`/`addBlocks` for real dependencies so subagents don't start
on work that isn't ready yet. Keep subjects short and imperative ("Add rate limiting to
/api/cart", not "Rate limiting").

For anything non-trivial, group tasks into phases explicitly in your own tracking (e.g.
"Phase 1: planning", "Phase 2: implementation", "Phase 3: review/PR") and say so to Erik
in one line — don't write a separate planning doc, the task list *is* the plan artifact.

Role → agent mapping (prompt-based, not separate agent definitions):

| Task type | Agent | Notes |
|---|---|---|
| Planning / architecture | `Plan` | Use before implementation on anything with real design decisions. Feed its output into the implementation task's description. |
| Research / "where is X" / "how does Y work" | `Explore` (quick lookups) or `general-purpose` (open-ended) | Keep it out of main context — summarize back. |
| UX/UI, component design, styling | `general-purpose`, prompt instructs it to load the `frontend-design` skill (and `DesignSync`/Figma tools if a design file is referenced) | Still needs its own worktree if it touches code. |
| Implementation (bug fix, feature, refactor) | `general-purpose` | Runs in its own worktree, ends by pushing a branch and opening a PR. |
| Security-sensitive changes | `general-purpose`, prompt instructs it to consult `secure-code-guardian`/`security-reviewer` skills | Auth, input handling, secrets. |

## Step 3 — Isolate each implementation subagent in a worktree

Before dispatching any subagent that will edit files, give it its own worktree so
parallel subagents never touch the same working directory:

1. Decide a short kebab-case name per task (e.g. `fix-cart-rate-limit`).
2. Either:
   - Use `EnterWorktree` yourself per-task right before spawning that subagent if you are
     driving the file changes directly (rare — prefer delegating), or
   - Tell the subagent explicitly, in its prompt, to call `EnterWorktree` with that name
     as its first action, then do all its work there. Agents run with their own working
     directory once inside a worktree, so this is safe to parallelize.
3. Launch subagents for independent tasks **in the same message** (parallel tool calls),
   never serially in one wrapper agent, per Erik's stated preference for dividing
   independent work across parallel subagents by default.
4. Each subagent's prompt must be self-contained (it has no memory of this
   conversation): state the goal, the exact task/file scope, which worktree name to use,
   that it should commit its own work, push its branch, and open a PR with `gh pr create`
   when done — then report back what it did and the PR URL.

## Step 4 — Track progress, don't poll

- Background agents notify you on completion — don't sleep/poll for them.
- When a subagent finishes, check its actual diff/PR before marking the task
  `completed` — trust but verify, per standard practice. An agent's summary describes
  intent, not necessarily what happened.
- Update the task list as things land: `TaskUpdate` to `completed`, unblock anything that
  was waiting on it (`TaskList` again to see what's newly available).
- If a subagent reports a blocker it can't resolve, don't silently retry it — create a
  task capturing the blocker and either resolve it yourself or ask Erik.

## Step 5 — Worktree cleanup

Once a subagent's PR is open (or merged, if Erik says to merge), remove its worktree:
`ExitWorktree` with `action: "remove"` if you're the one who entered it, or instruct the
subagent to leave it (`ExitWorktree action: "keep"`) if Erik wants to inspect it locally
first before cleanup. Default to removing once the PR exists — the branch and PR are the
durable record, not the worktree.

## Confirmation points

Per Erik's standing preferences, always pause for a real confirmation (not just a status
update) at:
- The initial plan/phase breakdown for anything non-trivial, before spawning subagents —
  Erik prefers understanding the plan before implementation begins.
- Before any subagent pushes to a shared/production branch directly (should never happen
  — subagents push their own feature branch and PR, never to `main`).
- Before merging a PR — orchestrating up to "PR open" is the default; merging is a
  separate ask unless Erik says otherwise up front.
- Before anything destructive (force-push, deleting a worktree with uncommitted changes,
  `git reset --hard`, etc.) — same bar as normal session behavior.

Within those bounds, keep the pipeline moving autonomously — that's the point of this
skill.

## Notes

- If a task is small enough to just do directly (one file, one obvious fix), don't spin
  up the whole apparatus — say so and do it inline. This skill is for tasks with real
  breadth (multiple files/areas, or explicit delegation requests), not everything Erik
  says.
- Don't create a written plan/PRD file for this — the native task list is the tracking
  artifact. Reserve markdown docs for when Erik explicitly asks for one.
- If Erik switches topics mid-orchestration ("actually, different thing"), treat it as a
  clean slate per his standing preference — don't fold the new ask into the running task
  list unless he says it's related.
