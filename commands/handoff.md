---
description: Post a handoff to an agent's agent-bus inbox, e.g. /handoff tester "UI ready — run bun test".
---

Post a handoff to the target agent's inbox.

1. `$1` is the agent (dev, reviewer, tester, memory-keeper, designer, manager); everything after is the message.
2. Partition: from your context/config (default: repo folder name lowercased). Inbox map: dev→`<p>/dev`, reviewer→`<p>/review`, tester→`<p>/tester`, memory-keeper→`<p>/docs`, designer→`<p>/design`, manager→`<p>/manager`.
3. Post with the bash tool: `agent-bus post <p>/<inbox> "<message>"` — confirm exit 0.

Usage: /handoff <agent> <message...>
