---
description: Audit this project against the team-skills roster — agents and skills installed vs missing.
---

Run the status audit for this project:

1. Check what exists: `.opencode/agents/*.md` (installed agents), `docs/agents/*.md` (canonical prompts), `.opencode/skills/*` (skills).
2. Compare against the lily roster: `~/Development/team-skills/scripts/setup.sh list` for agent names, `~/Development/skills/bundled-skills/` for skill sets.
3. Report a table: agent | installed? | prompt present? | notes; same for skills.
4. Recommend the exact next command for anything missing (`/add-agent <agent>`, `/add-skill <set>`, `/init` for a full bootstrap). $ARGUMENTS
