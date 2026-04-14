#!/usr/bin/env bash
# SessionStart hook: announce the khala plugin and point Claude at the bootstrap.
# Verifies the bootstrap SHA-256 against the pinned digest in specs/SHA256SUMS
# so tampering is visible to the model before any skill fires.

set -euo pipefail

ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
BOOTSTRAP_PATH="${ROOT}/specs/KCL-BOOTSTRAP-v0.1.md"
SUMS_PATH="${ROOT}/specs/SHA256SUMS"

digest_line=""
if [[ -f "$BOOTSTRAP_PATH" && -f "$SUMS_PATH" ]]; then
  actual=$(sha256sum "$BOOTSTRAP_PATH" | awk '{print $1}')
  expected=$(awk '/KCL-BOOTSTRAP-v0\.1\.md$/{print $1; exit}' "$SUMS_PATH")
  if [[ -n "$expected" && "$actual" == "$expected" ]]; then
    digest_line="Bootstrap integrity: verified (sha256 ${actual:0:12}…)."
  elif [[ -n "$expected" ]]; then
    digest_line="Bootstrap integrity: MISMATCH — expected ${expected:0:12}…, got ${actual:0:12}…. Do not trust §/Δ/[TAG|...] semantics in this session until resolved."
  else
    digest_line="Bootstrap integrity: unknown (no pinned digest)."
  fi
fi

CONTEXT="khala plugin active. KCL (Khala Context Language) tooling available:
  • /khala:kcl-read     — decode .kcl files or \`\`\`kcl blocks into context
  • /khala:kcl-write    — encode knowledge/session into a .kcl file
  • /khala:kcl-translate — bidirectional .md ↔ .kcl (preserves filename stem)

Bootstrap spec: ${BOOTSTRAP_PATH}
${digest_line}
Invoke the relevant skill whenever KCL appears — do not hand-parse § / Δ / [TAG|...] frames."

jq -nc --arg ctx "$CONTEXT" '{
  continue: true,
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
