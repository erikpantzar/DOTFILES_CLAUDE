# Personal Claude Code Config
# Last updated: April 2026
# Rule: if removing a line wouldn't change Claude's behaviour, it's gone.

# Identity
Web-focused developer expanding into broader problem domains.
Strong preference for clean, composable, readable code over clever code.
Design sensibility matters — frontend work should look intentional, not generated.

# How I work
- I prefer to understand the plan before implementation begins
- Ask me if the approach is unclear — don't assume and proceed
- When switching tasks mid-session, I'll say so. Treat it as a clean slate.
- Prefer one focused task per session over sprawling multi-file changes

# Code principles (applies everywhere)
- Readable over clever. Future-me is the audience.
- Explicit over implicit. No magic.
- Small functions. One responsibility.
- Errors must be handled, not swallowed.
- No console.log left in — use the logger.
- No hardcoded secrets or API keys, ever.

# DO NOT
- Do NOT suggest switching frameworks or major dependencies unprompted
- Do NOT add dependencies to solve problems I can solve in 5 lines
- Do NOT generate boilerplate I didn't ask for
- Do NOT make multiple file changes without confirming the plan first
- Do NOT use comments to explain what the code does — only why
- Do NOT pad responses. If the answer is short, keep it short.

# Verification
Always tell me how to verify your changes. For every non-trivial edit, provide:
- The command to run (test, typecheck, lint, or build)
- What passing output looks like
If you cannot verify it, flag it explicitly.

# Token efficiency
- Prefer subagents for research tasks — keep main context clean for implementation
- When a task splits into independent parts (multiple tickets/files/areas), divide it across parallel subagents by default — don't run them serially in one agent, and don't wait to be asked
- Use /btw for quick lookups, not main thread
- Scope investigations narrowly — read the files you need, not the whole repo
- When context is getting long, suggest /compact before I have to ask

# Compaction instructions
When compacting, always preserve:
- The full list of files modified this session
- Current test/build status
- Any decisions we made about approach or architecture
- Unresolved open questions

# --- Project-specific details belong in .claude/CLAUDE.md per repo ---
# --- Stack, structure, test commands, gotchas go there, not here ---
