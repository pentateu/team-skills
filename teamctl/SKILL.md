---
name: team-skills
description: Bootstrap or update a project with the standard agent roster (dev, reviewer, tester, memory-keeper, designer, manager) and the bundled skills (standards + UI) — so every opencode terminal in the project gets the same agents and skills. Use when the user says "teamctl skills", "init", "add-agent", "sync", "set up my agents", "install the agents/skills", "bootstrap this project", "add the reviewer agent", or when a project is missing agents or skills under .opencode/ or docs/agents/.
---

# team-skills — agents & skills installer

team-skills installs the standard agent roster and skill library into any project (new
or existing). It is generic — tied to no project. It renders detail templates,
then customizes them with the target project's context (tech stack, surfaces,
doc conventions, commands).

## Canonical repo (git)

`~/Development/skills` — the source of everything this skill installs:

```
  ~/Development/skills/
  teamctl/
    SKILL.md                        # this skill
    agents.json                     # agent roster manifest (names, templates, descriptions)
    templates/
      agents/dev-orchestrator.tmpl.md   # dev prompt (generic, <project> placeholders)
      agents/reviewer.tmpl.md
      agents/tester.tmpl.md
      agents/memory-keeper.tmpl.md
      agents/designer.tmpl.md
      agents/manager.tmpl.md
      agent-config.tmpl.md              # memory-keeper .opencode config template
      install-memory-keeper.sh          # launchd scheduler for memory-keeper
      opencode.json.tmpl                # per-project plugin config (envsitter-guard + plannotator)
    scripts/setup.sh                 # installer CLI (init / add-agent / update / skills)
  bundled-skills/                   # skills installed into projects
    docs-standards, rust-standards, react-ts-vite-standards, ios-swift-standards,
    monorepo-protocol-standards, playwright-best-practices, playwright-cli,
    agent-browser, webapp-testing, impeccable, ui-skills
```

## Agent roster (`teamctl/agents.json`)

| Agent | Canonical prompt (docs/agents/) | opencode config (.opencode/agents/) |
|---|---|---|
| `dev` | dev-orchestrator.md | dev.md |
| `reviewer` | reviewer.md | reviewer.md |
| `tester` | tester.md | tester.md |
| `memory-keeper` | memory-keeper.md | memory-keeper.md |
| `designer` | designer.md | designer.md |
| `manager` | manager.md | manager.md |

Placeholders rendered at install: `<project>`,
`<project_name>` (display name), `<repo_root>` (absolute path). All other
`<...>` tokens in prompts are command-example syntax and stay untouched.

Every agent uses **ASD-STE100 Simplified Technical English** when talking to
the human and when writing high-level designs, plans, or feedback intended
for human review (short sentences, active voice, one word one meaning, no
jargon — see each template's "Communication" section).

## Plugin config (installed with every command)

Every `init`, `add-agent`, and `update` also installs
`.opencode/opencode.json` in the project (from `templates/opencode.json.tmpl`):

- **envsitter-guard** — the `.env` security guard.
- **@plannotator/opencode** — its `submit_plan` tool opens a plan document in
  the browser for annotation. `planningAgents` (`["plan", "reviewer", "designer"]`)
  controls which agents get the tool; add other agent names there to grant it.

**Merge, not clobber.** If the project already declares plugins (in its
`.opencode/opencode.json` or a project-root `opencode.json`), the template's
plugin list is merged in — existing plugins are preserved and deduplicated by
plugin name, and every other existing config key is kept. If the merge would
change a customized file, the project's file is kept and the merged version is
written as `opencode.json.new` (diff + merge, or `--force`). A
project-root `opencode.json` is never modified.

**Restart required.** Plugins load at opencode startup: after any install,
restart opencode in the project before `submit_plan` is available.

## Workflow: init (new project bootstrap)

1. **Context.** Read the project: `AGENTS.md`, `docs/` layout, stack files
   (`package.json`, `Cargo.toml`, `pyproject.toml`, …), any existing
   `.opencode/` and `.cursor/`. If the project already has agents or skills,
   note what exists before touching anything.
2. **Ask the user** (never guess): project display name
   (default: folder name lowercased), which agents to install (default: all),
   which skill set (`standards` for dev/backend/web/iOS standards, `ui` for
   impeccable + ui-skills, `all`, `none`), and an optional `--model` per agent.
     identity (dev → `<partition>/dev`, reviewer → `<partition>/review`,
     tester → `<partition>/tester`, memory-keeper → `<partition>/docs`,
     designer → `<partition>/design`, manager → `<partition>/manager`), 4h
     timeout, at the end of every task/cycle with no pending human question.
   - **Launchd question** — only ask if `memory-keeper` is in the roster,
     plain wording: "Run the memory-keeper docs sweep automatically twice a
     day via macOS launchd (even when no session is open)?" Yes = registers
     `com.<partition>.memorykeeper` via `install-memory-keeper.sh install`;
     No = run manually with `/memory`.
3. **Scaffold** with the CLI:
   `~/Development/team-skills/scripts/setup.sh init <repo_root> [partition] --project-name "..." [--agents dev,reviewer,tester,memory-keeper,designer] [--skills standards] [--model ...]`
4. **Customize** each generated prompt to this project. This is the core step —
   do it for every agent, after the scaffold, and show the user what changed:
   - dev: rewrite the surfaces/stack the dev owns, verification commands,
     worktree/merge conventions, ledger location.
   - reviewer: rewrite the review matrix (file-type → checklist) and the
     design-authority path (`<repo_root>/DESIGN.md` or whatever the project
     uses — check for DESIGN.md / docs/PRODUCT.md).
   - tester: rewrite the owned surfaces (web apps, mobile, desktop), run
     commands, report location.
    - memory-keeper: doc taxonomy per the project's actual docs/ tree.
    - manager: workspace-level, not per-project — install it once at the
      workspace root (e.g. `/Users/rafael/Development`) with
      `setup.sh add-agent manager`; it enumerates the
      projects under the workspace itself. A per-project manager install
      would shadow the workspace one.
    - Keep the shared protocols (comms, worktrees, dispatch contract) intact.
5. **Conflicts.** setup.sh never silently clobbers: if a target file exists and
   differs from the new render, it keeps the project's file and writes the new
   version as `<file>.new`. For each sidecar, show `diff` to the user and
   ask: overwrite with the new version / keep the project's version / merge.
   On overwrite or merge, remove the sidecar. `--force` skips the asking.
   The plugin config (`install_config`) merges rather than replaces: a project
   with its own `opencode.json` keeps every existing plugin; the template's
   plugins (envsitter-guard + plannotator) are appended. When the project
   already has a config that lacks the template plugins, the merged version is
   written to `.opencode/opencode.json.new` for the human to review
   (still never applied silently).
6. **Verify.** Check every generated `.opencode/agents/*.md` has valid
   frontmatter (description, mode, optional model) and that referenced files
   exist. Run `setup.sh list` for the roster.
7. **Report** what was installed and tell the user to restart opencode — the
   running session keeps the old config until then.

## Workflow: add-agent (extend an existing project)

1. Read the project context (as above) and confirm the partition from its
   existing agents (grep `.opencode/agents/*.md` and `docs/agents/*.md` for
   the partition if not given).
2. Confirm the agents to add (e.g. `tester` when only `dev`+`reviewer` exist).
3. `~/Development/team-skills/scripts/setup.sh add-agent <repo_root> <partition> <agent>... [--project-name "..."] [--model ...]`
4. Customize the new prompts to the project's stack (same rules as init).
5. If the target's `docs/agents/` already has a customized version of the
   prompt, setup.sh keeps it and writes `<file>.new` — show the diff and
   ask: overwrite / keep / merge.
6. Report + restart reminder.

## Workflow: update (re-render existing projects)

- `setup.sh update <repo_root> [partition] [agents...]` re-renders agents from
  the current templates — **only agents already installed** (missing ones are
  reported; use add-agent). Run it when templates changed.
- Customizations are always kept: conflicting files are preserved and the new
  version lands as `<file>.new`. For each sidecar, diff + ask
  (overwrite / keep / merge), then remove the sidecar. `--force` overwrites
  without asking.

## Workflow: role commands (start/resume an agent session)

The reviewer and designer use **Plannotator** (`@plannotator/opencode`,
installed per-project in `.opencode/opencode.json` by every setup command): its
`submit_plan` tool opens a document in the browser for annotation. This
requires the agent to be listed in the plugin's `planningAgents`
(`["plan", "reviewer", "designer"]`) — add other agent names there if they
should get the tool too.

- The designer routes every plan it writes through `submit_plan` — high-level
  AND detailed (human approval is the gate between stages).
- The reviewer uses `submit_plan` **only when a plan/design review surfaces
  solution options that need a human decision**. If the review is only
  feedback about the proposed solutions, the reviewer posts it directly to
  the designer on `<project>/design`, and the designer improves/fixes the
  plan docs. Plan/design reviews verify every claim and ask "is there a
  better solution?" for each solution, presenting options with pros/cons.

Run any of these in a project that has `docs/agents/` (installed by `init`):

- `/dev` — adopt the dev agent role; injects
  `docs/agents/dev-orchestrator.md` in full as the session role.
- `/review` — adopt the reviewer role (`docs/agents/reviewer.md`).
- `/tester` — adopt the tester role (`docs/agents/tester.md`).
- `/memory` — adopt the memory-keeper role (`docs/agents/memory-keeper.md`).
- `/designer` — adopt the designer/planner role (`docs/agents/designer.md`):
  grill session → grounded research → high-level plan (iterate) → Plannotator
  review → detailed plan → Plannotator review → register in ledger + notify.
  Never codes; plans live in `docs/plans/` as `plan_high_level_*.md` and
  `plan_*.md` with requirements at the top.
- `/manager` — adopt the workspace manager role
  (`docs/agents/manager.md`): ONE manager for all in-flight projects under the
  workspace (installed at the workspace root, e.g. `~/Development`). Keeps
  `~/Development/BACKLOG.md`, queries each project's bus with `history`
  WITHOUT consuming, dispatches to any project's agent inbox; never codes.
  No `submit_plan` (it doesn't produce plans for approval).
- `/fresh [role]` — restart this agent from scratch: voids all prior
  conversation and task state, re-adopts ONLY the role prompt (re-read in
  full), ready for a new task. Instant behavioral reset; for a fully
  token-clean context use `/compact` then `/fresh`, or `/new` then the
  matching `/<role>` command.
- ~~`/listen`~~ — retired: tells arrive as prompts; nothing to listen for.
  blocked) — never a shell while loop, never `read` after `wait`; `--once`
  handles a single message. **End-of-task rule:** every agent automatically
  returns to the bus when a task/cycle ends without a pending human question;
  `/listen` is the manual resume after interruptions or restarts.
  Listening is `wait` only — no hooks, no plugins.

Each injects the full canonical prompt via a `@file` reference, makes it the
binding role of the current agent, and instructs: never let this context go —
if compaction discards it, re-read the file in full and restore it before
continuing. If the project has no `docs/agents/`, the command falls back to
the canonical template and tells the user to run `/init`.

## Workflow: sync (refresh the canonical repo itself)

When the source projects (e.g. `~/Development/AI_Tutor/docs/agents/`,
`.opencode/skills/`, `.cursor/skills/`) have evolved:

1. Copy updated canonical prompts into `teamctl/templates/agents/` (genericize:
   replace project names with `<project>` / `<project_name>` / `<repo_root>`,
   never introduce new hardcoded paths).
2. Copy updated skills into `bundled-skills/`.
3. Update `teamctl/agents.json` descriptions if the roster changed.
4. `git add -A && git commit` in `~/Development/skills`.
5. Optionally run `update` on installed projects.

## Rules

- **Never invent project context.** Ask when the stack, surfaces, partition,
  or design authority is unclear. Customized agents are worse than uninstalled
  ones.
- **Never overwrite silently.** Project-customized files are the project's
  property. Diff + ask.
- **Keep prompts canonical.** The templates in `teamctl/templates/` are the single
  source; per-project versions live in the project's `docs/agents/`, never
  edited in the templates repo.
- After any install, the user must restart opencode for agents/skills to load.
