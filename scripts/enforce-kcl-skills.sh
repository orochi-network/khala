#!/usr/bin/env bash
# PreToolUse hook: when Claude is about to Read/Write/Edit a .kcl (or KCL spec
# .md) file, inject a reminder to route through the appropriate khala skill.
# Never blocks — only nudges via additionalContext so the model can still
# proceed if it has already loaded the bootstrap this session.

set -euo pipefail

EVENT=$(cat)
TOOL=$(printf '%s' "$EVENT" | jq -r '.tool_name // ""')
PATH_ARG=$(printf '%s' "$EVENT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Only act on .kcl targets, or on KCL-SPEC / KCL-BOOTSTRAP markdown files.
is_kcl_target=0
case "$PATH_ARG" in
  *.kcl)                                    is_kcl_target=1 ;;
  *KCL-SPEC*.md|*KCL-BOOTSTRAP*.md)         is_kcl_target=1 ;;
esac

if [[ "$is_kcl_target" -eq 0 ]]; then
  exit 0
fi

case "$TOOL" in
  Read)
    MSG="About to Read a KCL artifact (${PATH_ARG}). If you have not already, invoke khala:kcl-read so the bootstrap spec is loaded and the payload is decoded by tier rather than line-by-line."
    ;;
  Write)
    MSG="About to Write a .kcl file (${PATH_ARG}). Route through khala:kcl-write — it enforces the header order (§KCL_V0.1 → §META → §TRUST → §ONTO? → §TOOLS? → §USE* → body), mandatory trust markers, ASCII-pipe frames, and domain-pack compliance."
    ;;
  Edit)
    MSG="About to Edit a KCL artifact (${PATH_ARG}). Ensure the bootstrap is loaded (via khala:kcl-read or khala:kcl-write) before modifying § / Δ / [TAG|...] structures — ad-hoc edits can break tier ordering, trust markers, or frame grammar."
    ;;
  *)
    exit 0
    ;;
esac

jq -nc --arg ctx "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
