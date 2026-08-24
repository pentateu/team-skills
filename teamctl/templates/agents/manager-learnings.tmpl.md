# Manager Learnings — <project_name>

Append-only. Manager reads this at every wake, before the loop. Each row is a scar worth a rule — cite it when it fires instead of guessing.

| date | trigger HT / page | ask → answer → action | rule to apply next time |
|---|---|---|---|
| 2026-08-24 | HT-92 merge `e63ae5b` → tip `E0425 sessions_answered` | Branch compiled; merge interleave broke `development` — no post-merge `cargo check` before push → 20 min red tip | Post-merge gate: after every `git merge --no-ff` to `development`, `cargo check --workspace` on merged tip before push. Manager verifies `git log origin/development` vs check green. |
| 2026-08-24 | HT-69 Ph1 (`032`) vs HT-82 (`032_learner_portrait.sql`) | Two foundations claimed same migration number | Pre-dispatch: `ls crates/events/migrations \| tail` → next free = `max+1`; pin gap via migrator test (`032 gap reserved @897f8d3`). Manager pastes pin in dispatch. |
| 2026-08-24 | HT-78..83 all `progress` | Board 6× progress, `git worktree list` showed 1 real branch | Normalize progress: one `progress` = one worktree/branch with recent commit. Manager demotes surplus `progress → todo` with comment. |
| 2026-08-24 | dev1 Q on `Custom curricula — detailed …` page, `Design` busy | Old path would queue on busy Design and pollute context | Design-blocked proxy: `busy/STUCK/ENDED MID-TOOL` Design → ephemeral `designer` subagent writes directly to page (`ot comment reply` / `page update`). Hold only if subagent returns `NEEDS_HUMAN`. |
| 2026-08-24 | dev3/dev4 `STUCK` on `0X Alpha` (ZEN `x-preview-f-free`) | `read_latest --json` → `idle+STUCK+empty lastAssistant` | Model fallback: `idle+STUCK + live==Alpha + same ask ≥2 passes` → `teamctl model set muse-spark-1.2 + tell nudge` → wait `responded` → `model set Alpha` back. Muse fails twice → escalate with both JSON packets. |
| 2026-08-24 | 22 tickets `verify`/`progress` stale at cutover | No owner, work already on `origin/development` | Board hygiene for orphans: manager may move with evidence comment (`branch + merge sha + tester signal`). Use `via <seat> token, manager pending` until `HOMETUTOR_TICKETS_TOKEN_MANAGER` minted. |
| 2026-08-24 | Human answered `dev1` directly, bypassing manager | Manager missed Q→A, couldn't learn `kill-switch GATE` decision | Answer through manager: `teamctl tell manager "answer for dev1: …"` — manager sees ask+answer+action and extracts rule. Direct `tell dev1` starves base. |

*Manager: load `docs-standards` before editing this file. Keep rows token-tight — one idea per row.*
