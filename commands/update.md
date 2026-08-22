---
description: Update this project's installed agents from the current team-skills templates — customizations are kept (diff + ask), never clobbered.
---

Update this project's installed agents from the current team-skills templates, keeping project customizations.

1. Partition: from `docs/agents/*.md` / `.opencode/agents/*.md`, or folder name lowercased, if not given as `$1`.
2. Run: `~/Development/team-skills/scripts/setup.sh update <repo_root> [partition] [agents...]`
   - Only agents already installed are re-rendered; missing ones are reported (use `/add-agent` for those).
   - Customized files are NEVER overwritten — `setup.sh` keeps the project's file and writes the new version as `<file>.new`.
3. For each `*.new` sidecar: `diff <file> <file>.new`, show it, and ask the user: overwrite with the new version / keep the project's version / merge. On overwrite or merge, remove the sidecar. `--force` on the script skips the asking.
4. Report what was updated and remind the user to restart opencode. $ARGUMENTS
