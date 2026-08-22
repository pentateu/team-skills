---
description: Listen on your agent-bus inbox — one blocking wait, act, repeat.
---

Resume listening on your agent-bus inbox.

- **Role**: <role> — from your loaded role prompt (dev / reviewer / tester / memory-keeper / designer / manager). `$1` overrides it.
- **Partition**: <partition> — from your config (default: repo folder name lowercased). Your inbox: `<partition>/<role-inbox>`.

Execute exactly this, one bash call at a time (4h tool timeout):

    agent-bus wait '<partition>/<role-inbox>' --as <role> --timeout 4h

- exit 0 → the printed message is your task — act on it per your role prompt, then run the wait again.
- exit 2 → nothing pending — run the wait again.
- Never wrap it in a shell `while` loop; never `read` after `wait`. Only stop when the user says stop.
- `/listen --once` → handle exactly one message (or 4h timeout), then return.

No status check, no re-derivation — just wait.
