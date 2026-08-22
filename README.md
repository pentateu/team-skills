# team-skills — agents & skills installer

Companion repo to [`teamctl`](https://github.com/pentateu/teamctl): the agent
roster, role prompts, and bundled skill library it installs into projects.

    team-skills/
      teamctl/
        SKILL.md                the installer skill (bootstrap / add-agent / update)
        agents.json             roster manifest (agent → prompt template + config body)
        templates/agents/*.md   canonical role prompts (dev, reviewer, tester,
                                memory-keeper, designer, manager)
        templates/comms.md      agent messaging protocol (teamctl tell)
        scripts/setup.sh        project installer CLI (init/add-agent/update/skills)
      bundled-skills/           standards & tooling skills installed into projects
      commands/                 opencode slash-commands (/init, /fresh, /handoff, …)

## Setup (new machine)

    git clone git@github.com:pentateu/team-skills.git ~/Development/team-skills
    ./install.sh          # clones/updates, registers skill path, symlinks commands

## Bootstrap a project

    cd ~/Development/AI_Tutor
    teamctl init          # roster + agents + skills + comms protocol

or manually: `teamctl/setup.sh init <repo_root>`.

## Update

    cd ~/Development/team-skills && git pull
    cd ~/Development/AI_Tutor && /update     # diff + ask, never clobbers

Messaging between agents is **teamctl tell** — see `teamctl/templates/comms.md`.
