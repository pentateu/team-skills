#!/usr/bin/env bash
# setup.sh — install team-skills agents and skills into a project.
#
# Usage:
#   setup.sh init <repo_root> [partition] [options]
#   setup.sh add-agent <repo_root> <partition> <agent> [<agent>...] [options]
#   setup.sh update <repo_root> [partition] [agents...]   # re-render installed agents
#   setup.sh skills <repo_root> [standards|ui|all]        # install bundled skills
#
# Options:
#   --project-name "Display Name"   default: partition
#   --model provider/model-id       model for generated agent configs
#   --agents a,b,c                  agents to install (init default: all)
#   --skills standards|ui|all|none  skill set (init default: standards)
#   --force                         overwrite customized files (default: never)
#
# Update/install never silently clobbers: if a target file exists and differs
# from the new render, the project's file is kept and the new version is
# written next to it as <file>.new (diff + merge, or --force to overwrite).
#
# Agent messaging is teamctl tell (see templates comms section) — no bus, no
# listening loops.
#
# Placeholders rendered at install: <project>, <project_name>, <repo_root>.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
MANIFEST="$REPO_ROOT/teamctl/agents.json"
SKILLS_BUNDLE="$REPO_ROOT/bundled-skills"

command -v jq >/dev/null || { echo "error: jq required (brew install jq)" >&2; exit 1; }

fail() { echo "error: $*" >&2; exit 1; }

canonical_partition() {
  basename "$1" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '_'
}

# render placeholders: <project_name> MUST be replaced before <project>
render() {
  local in="$1" out="$2" partition="$3" name="$4" root="$5"
  sed -e "s|<project_name>|$name|g" \
      -e "s|<project>|$partition|g" \
      -e "s|<repo_root>|$root|g" "$in" > "$out"
}

agent_names() { jq -r '.agents | keys | join(", ")' "$MANIFEST"; }

FORCE=0

# Place tmp content at dest; never silently clobber customizations.
#   missing -> install; identical -> up to date; differs -> CONFLICT: keep the
#   project's file and write the new version to dest.new (or overwrite
#   with --force).
put_temp() {
  local tmp="$1" dest="$2"
  if [[ ! -e "$dest" ]]; then
    mv "$tmp" "$dest"
  elif cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "  up to date: $dest"
  elif [[ "$FORCE" == "1" ]]; then
    mv "$tmp" "$dest"
    echo "  overwrote (--force): $dest"
  else
    mv "$tmp" "$dest.new"
    echo "  CONFLICT: $dest is customized — kept yours; new version at $dest.new (diff + merge, or rm; --force to overwrite)"
  fi
}

# Render template with placeholders into dest (conflict-safe).
put_rendered() {
  local in="$1" dest="$2" partition="$3" name="$4" root="$5"
  local tmp; tmp="$(mktemp)"
  render "$in" "$tmp" "$partition" "$name" "$root"
  put_temp "$tmp" "$dest"
}

# Copy a static file into dest (conflict-safe).
put_copy() {
  local src="$1" dest="$2"
  local tmp; tmp="$(mktemp)"
  cp "$src" "$tmp"
  put_temp "$tmp" "$dest"
}

# Merge the plugin array from an existing opencode config with the template's,
# preserving every existing top-level key and every existing plugin (deduped by
# plugin name; the existing entry wins on a collision). Writes the merged JSON
# to $out. Exits non-zero if either input is not valid JSON.
merge_opencode_plugins() {
  local existing="$1" template="$2" out="$3"
  jq -n \
    --slurpfile e "$existing" \
    --slurpfile t "$template" '
      def plugin_name(p): if (p | type) == "array" then p[0] else p end;
      def same_plugin(a; b): plugin_name(a) == plugin_name(b);
      ($e[0] // {}) as $ed
      | ($t[0] // {}) as $tpl
      | ($ed.plugin // []) as $existing_plugins
      | ((($tpl.plugin // []) + $existing_plugins)
          | reduce .[] as $p ([]; if any(.[]; same_plugin(.; $p)) then . else . + [$p] end)) as $plugins
      | $ed
        | .["$schema"] = (if $ed["$schema"] == null then $tpl["$schema"] else $ed["$schema"] end)
        | .plugin = $plugins
    ' > "$out"
}

# Semantic (key/value) equality, ignoring key order and formatting — used so
# a merge that jq rewrote differently still counts as "up to date".
json_equal() {
  local a="$1" b="$2"
  [[ "$(jq -S -c . "$a" 2>/dev/null)" == "$(jq -S -c . "$b" 2>/dev/null)" ]]
}

# Install the opencode plugin config into a project's .opencode/opencode.json.
# Conflict-safe like every other install: if the target already exists and
# differs (semantically), the project's file is kept and the merged version is
# written as opencode.json.new (diff + merge, or --force to overwrite).
#
# Existing plugins are preserved, not clobbered: the template's plugin list is
# merged with whatever the project already declares, in .opencode/opencode.json
# or (falling back) in the project-root opencode.json. A project with its own
# plugins keeps them all.
install_config() {
  local repo="$1"
  local repo_abs dest existing template tmp
  repo_abs="$(cd "$repo" && pwd)"
  mkdir -p "$repo_abs/.opencode"
  dest="$repo_abs/.opencode/opencode.json"
  template="$REPO_ROOT/teamctl/templates/opencode.json.tmpl"
  existing=""
  [[ -f "$dest" ]] && existing="$dest"
  [[ -z "$existing" && -f "$repo_abs/opencode.json" ]] && existing="$repo_abs/opencode.json"
  tmp="$(mktemp)"
  if [[ -n "$existing" ]]; then
    if merge_opencode_plugins "$existing" "$template" "$tmp"; then
      if json_equal "$existing" "$tmp"; then
        rm -f "$tmp"
        echo "  up to date: $dest"
        return
      fi
    else
      cp "$template" "$tmp"
    fi
  else
    cp "$template" "$tmp"
  fi
  put_temp "$tmp" "$dest"
}

install_agent() {
  local repo="$1" partition="$2" agent="$3" name="$4"
  local entry canonical template description mode config_body
  entry="$(jq -c --arg a "$agent" '.agents[$a]' "$MANIFEST")"
  [[ "$entry" != "null" ]] || fail "unknown agent: $agent (known: $(agent_names))"
  canonical="$(jq -r '.canonical' <<<"$entry")"
  template="$(jq -r '.template' <<<"$entry")"
  description="$(jq -r '.description' <<<"$entry")"
  mode="$(jq -r '.mode' <<<"$entry")"
  config_body="$(jq -r '.config_body' <<<"$entry")"

  local repo_abs
  repo_abs="$(cd "$repo" && pwd)"
  mkdir -p "$repo_abs/docs/agents" "$repo_abs/.opencode/agents"

  put_rendered "$REPO_ROOT/$template" "$repo_abs/docs/agents/$canonical" "$partition" "$name" "$repo_abs"

  local cfg_tmp; cfg_tmp="$(mktemp)"
  {
    printf -- '---\ndescription: "%s"\nmode: %s\n' "$description" "$mode"
    [[ -n "${MODEL:-}" ]] && printf 'model: %s\n' "$MODEL"
    printf -- '---\n\n%s\n' "$config_body"
  } | sed -e "s|<project_name>|$name|g" \
          -e "s|<project>|$partition|g" \
          -e "s|<repo_root>|$repo_abs|g" > "$cfg_tmp"
  put_temp "$cfg_tmp" "$repo_abs/.opencode/agents/$agent.md"

  if [[ "$agent" == "memory-keeper" ]]; then
    put_rendered "$REPO_ROOT/teamctl/templates/agent-config.tmpl.md" \
      "$repo_abs/docs/agents/agent-config.template.md" "$partition" "$name" "$repo_abs"
    put_copy "$REPO_ROOT/teamctl/templates/install-memory-keeper.sh" \
      "$repo_abs/docs/agents/install-memory-keeper.sh"
    chmod +x "$repo_abs/docs/agents/install-memory-keeper.sh"
  fi

  echo "agent $agent: done"
}

install_skills() {
  local repo="$1" set="$2"
  local repo_abs dest dir
  repo_abs="$(cd "$repo" && pwd)"
  dest="$repo_abs/.opencode/skills"
  case "$set" in
    standards)
      for dir in docs-standards rust-standards react-ts-vite-standards ios-swift-standards \
                 monorepo-protocol-standards playwright-best-practices playwright-cli \
                 agent-browser webapp-testing; do
        [[ -d "$SKILLS_BUNDLE/$dir" ]] && cp -R "$SKILLS_BUNDLE/$dir" "$dest/"
      done
      ;;
    ui)
      [[ -d "$SKILLS_BUNDLE/impeccable" ]] && cp -R "$SKILLS_BUNDLE/impeccable" "$dest/"
      [[ -d "$SKILLS_BUNDLE/ui-skills" ]] && cp -R "$SKILLS_BUNDLE/ui-skills" "$dest/"
      ;;
    all)
      cp -R "$SKILLS_BUNDLE/." "$dest/"
      ;;
    none) return ;;
    *) fail "unknown skill set: $set (standards|ui|all|none)" ;;
  esac
  echo "installed skills ($set) -> $dest"
}

cmd_init() {
  [[ $# -ge 1 ]] || fail "init <repo_root> [partition]"
  local repo="$1" partition=""
  shift
  [[ $# -ge 1 ]] && [[ "$1" != --* ]] && partition="$1" && shift
  [[ -n "$partition" ]] || partition="$(canonical_partition "$repo")"

  local name="$partition" agents="" skills="standards" model="${MODEL:-}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-name) name="$2"; shift 2 ;;
      --model) model="$2"; shift 2 ;;
      --agents) agents="$2"; shift 2 ;;
      --skills) skills="$2"; shift 2 ;;
      --force) FORCE=1; shift ;;
      *) fail "unknown option: $1" ;;
    esac
  done
  [[ -n "$agents" ]] || agents="$(agent_names)"

  echo "== skills init: $name ($partition) @ $repo"
  install_config "$repo"
  IFS=',' read -r -a list <<< "$agents"
  for a in "${list[@]}"; do
    a="$(echo "$a" | tr -d ' ')"
    [[ -z "$a" ]] || install_agent "$repo" "$partition" "$a" "$name"
  done
  install_skills "$repo" "$skills"
  echo "== done. Restart opencode in $repo to load the new agents/skills."
}

cmd_add_agent() {
  [[ $# -ge 3 ]] || fail "add-agent <repo_root> <partition> <agent> [<agent>...]"
  local repo="$1" partition="$2"
  shift 2
  local name="$partition"
  local agents=() model="${MODEL:-}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-name) name="$2"; shift 2 ;;
      --model) model="$2"; shift 2 ;;
      --force) FORCE=1; shift ;;
      --*) fail "unknown option: $1" ;;
      *) agents+=("$1"); shift ;;
    esac
  done
  [[ ${#agents[@]} -gt 0 ]] || fail "no agents given"
  install_config "$repo"
  for a in "${agents[@]}"; do
    install_agent "$repo" "$partition" "$a" "$name"
  done
  echo "== done. Restart opencode in $repo to load the new agents."
}

cmd_update() {
  [[ $# -ge 1 ]] || fail "update <repo_root> [partition]"
  local repo="$1" partition=""
  shift
  [[ $# -ge 1 ]] && [[ "$1" != --* ]] && partition="$1" && shift
  [[ -n "$partition" ]] || partition="$(canonical_partition "$repo")"
  local name="${PROJECT_NAME:-$partition}"
  local agents=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force) FORCE=1; shift ;;
      *) agents+=("$1"); shift ;;
    esac
  done
  if [[ ${#agents[@]} -gt 0 ]]; then
    install_config "$repo"
    for a in "${agents[@]}"; do install_agent "$repo" "$partition" "$a" "$name"; done
  else
    install_config "$repo"
    for a in $(jq -r '.agents | keys[]' "$MANIFEST"); do
      if [[ -f "$repo/.opencode/agents/$a.md" ]]; then
        install_agent "$repo" "$partition" "$a" "$name"
      else
        echo "agent $a: not installed in this project — add it with add-agent"
      fi
    done
  fi
  echo "== done."
}

cmd_skills() {
  [[ $# -ge 2 ]] || fail "skills <repo_root> [standards|ui|all|none]"
  install_skills "$1" "$2"
}

case "${1:-}" in
  init) shift; cmd_init "$@" ;;
  add-agent) shift; cmd_add_agent "$@" ;;
  update) shift; cmd_update "$@" ;;
  skills) shift; cmd_skills "$@" ;;
  list) jq -r '.agents | to_entries[] | "\(.key): \(.value.canonical) (mode \(.value.mode), inbox \(.value.inbox))"' "$MANIFEST" ;;
  *) sed -n '2,14p' "$0" ;;
esac
