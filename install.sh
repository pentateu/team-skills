#!/usr/bin/env bash
# install.sh — bootstrap team-skills on a new machine.
#
# Clones/updates the team-skills repo, registers the skill path in opencode's global
# config, and symlinks the /* commands. Idempotent: safe to re-run.
#
# Usage:
#   bash install.sh [dest]     # dest defaults to ~/Development/skills
#   LILY_HOME=... bash install.sh
set -euo pipefail

REPO_SSH="${TEAM_SKILLS_REPO:-git@github.com:pentateu/team-skills.git}"
DEST="${1:-${LILY_HOME:-$HOME/Development/skills}}"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"

log() { echo "== $*"; }

# 1. Get the repo onto this machine.
if [[ -d "$DEST/.git" ]]; then
  log "updating existing checkout at $DEST"
  git -C "$DEST" pull --ff-only
elif [[ -e "$DEST" ]]; then
  echo "error: $DEST exists and is not a git checkout" >&2
  exit 1
else
  log "cloning $REPO_SSH -> $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO_SSH" "$DEST"
fi

[[ -f "$DEST/SKILL.md" ]] || { echo "error: $DEST/SKILL.md missing after install" >&2; exit 1; }

# 2. jq is required by setup.sh.
command -v jq >/dev/null || {
  echo "warning: jq not found — setup.sh needs it." >&2
  case "$(uname -s)" in
    Darwin) echo "  brew install jq" >&2 ;;
    Linux)  echo "  sudo apt install jq   # or your distro equivalent" >&2 ;;
  esac
}

# 3. Register the skill path in the global opencode config (merge, never clobber).
mkdir -p "$OPENCODE_DIR/command"
CFG="$OPENCODE_DIR/opencode.jsonc"
touch "$CFG"
if command -v jq >/dev/null && jq -e . "$CFG" >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq --arg p "$DEST" '.skills.paths = ((.skills.paths // []) | if index($p) then . else . + [$p] end)' \
    "$CFG" > "$tmp" && mv "$tmp" "$CFG"
  log "registered skill path $DEST in $CFG"
elif [[ -s "$CFG" ]]; then
  echo "warning: $CFG is not plain JSON (comments?) — add manually:" >&2
  echo '  { "skills": { "paths": ["'"$DEST"'] } }' >&2
else
  printf '{\n  "$schema": "https://opencode.ai/config.json",\n  "skills": {\n    "paths": ["%s"]\n  }\n}\n' "$DEST" > "$CFG"
  log "created $CFG with skill path $DEST"
fi

# 4. Symlink every command globally.
for cmd in "$DEST"/commands/*.md; do
  ln -sf "$cmd" "$OPENCODE_DIR/command/$(basename "$cmd")"
done
log "symlinked $(ls "$DEST"/commands/*.md | wc -l | tr -d ' ') commands into $OPENCODE_DIR/command/"

log "done. Restart opencode, then run /init inside any project."
