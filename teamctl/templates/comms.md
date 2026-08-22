# Agent Comms — teamctl

Single source of truth for inter-agent messaging in this project. Agent files
reference this doc; they never restate it.

## Tool

`teamctl` sends messages directly into agents' opencode sessions via the
opencode API. **Run it from inside the project folder** so it reads
`.opencode/team.json` and connects to the project's server (`-C <repo-root>`
for an explicit root).

## Sending

    teamctl tell <target> "message"

- `<target>` = a seat name (`dev1`), a team name (`Team1`), or a comma list
  (`dev1,review1`). No topics, no prefixes.
- Delivery: busy seat → queued until its current turn ends; idle seat →
  delivered and processing starts immediately. Like a human typing in the
  terminal.
- A message starting with `-` needs `--` before it:
  `teamctl tell dev1 -- "- fix login"`.
- `--dry-run` shows what would be sent without sending.
- Keep tells short — a pointer + verdict/issue list; the detail lives in
  files the receiver reads.

## Receiving

**No listening loops, no polling, no wait command.** Messages arrive as new
prompts in your session automatically. End your turn when done; an incoming
tell wakes you. Do not sit idle waiting for instructions unless you need
human input — ask and stay interactive in that case.

## Status

    teamctl status        # seat table: seat / team / state (idle|busy) / last activity

Use it to check whether a teammate is free or already acting, and to confirm
a seat exists before telling it.

## Roster

`.opencode/team.json`: seats grouped into teams; pairing is number-matched
(devN ↔ reviewN ↔ testerN) unless the roster says otherwise. A seat needs a
live session to receive tells ("no live session — run `teamctl up`").

## Doc changes: no notifications

Doc changes are **not** announced. Discovery is by construction: statuses
live in `docs/ledger.md` and every change is committed+pushed immediately
(ledger discipline), so anyone acting on a plan/bug/doc reads the ledger
first. Tell an agent directly only when you need action from that agent —
not to announce that a file changed.

## Retired

`agent-bus` (post/wait/read/history, topics/partitions, cursors, exit-code
branching) is retired for agent comms. Historical plans/reviews may mention
it — that is history, not procedure.
