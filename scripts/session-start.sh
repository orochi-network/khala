#!/usr/bin/env bash
# SessionStart hook: announce the khala plugin and point Claude at the bootstrap.
# The bootstrap itself is loaded lazily by each skill's Step 1; here we just
# ensure Claude knows the skills + bootstrap exist from turn zero.

set -euo pipefail

BOOTSTRAP_PATH="${CLAUDE_PLUGIN_ROOT:-.}/specs/KCL-BOOTSTRAP-v0.1.md"

read -r -d '' CONTEXT <<EOF || true
khala plugin active. KCL (Khala Context Language) tooling available:
  • /khala:kcl-read     — decode .kcl files or \`\`\`kcl blocks into context
  • /khala:kcl-write    — encode knowledge/session into a .kcl file
  • /khala:kcl-translate — bidirectional .md ↔ .kcl (preserves filename stem)

Bootstrap spec: ${BOOTSTRAP_PATH}
Invoke the relevant skill whenever KCL appears — do not hand-parse § / Δ / [TAG|...] frames.
EOF

jq -nc --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
