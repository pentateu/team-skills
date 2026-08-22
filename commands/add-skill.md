---
description: Install a skill set into this project without touching agents: standards, ui, or all.
---

Install skills into this project.

1. `$1` is the skill set: `standards` (dev/backend/web/iOS/protocol standards + testing), `ui` (impeccable + ui-skills), or `all`.
2. Run: `~/Development/team-skills/scripts/setup.sh skills <repo_root> <set>`
3. If a skill folder already exists in `.opencode/skills/` and differs, show the diff and ask before overwriting.
4. Report what was installed and remind the user to restart opencode to load them. $ARGUMENTS
