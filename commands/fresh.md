---
description: Restart this agent from scratch — keep only the role prompt, ready for a new task.
---

Fresh start. Everything before this message is void: drop all prior task state and conversation.

- You are <role> (from your loaded prompt; `$1` overrides, e.g. `/fresh reviewer`).
- Re-adopt ONLY your role prompt: read `docs/agents/<role>.md` in full; if missing, read `~/Development/team-skills/templates/agents/<role>.tmpl.md` and tell the user to run `/init`. Re-assert it — never let it go; if compaction discards it, re-read in full.
- Files are untouched — nothing is reverted (use `/undo` for that).
- State your role in one line and wait for the new task.

For a fully token-clean context: `/compact` then `/fresh`, or `/new` then the matching `/<role>`.
