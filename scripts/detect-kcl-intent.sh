#!/usr/bin/env bash
# UserPromptSubmit hook: nudge the right skill when the user's prompt contains
# KCL content or mentions .kcl files, so Claude routes through kcl-read/write/
# translate instead of improvising.

set -euo pipefail

EVENT=$(cat)
PROMPT=$(printf '%s' "$EVENT" | jq -r '.prompt // ""')

# Cap the prompt length before running regexes. The hook timeout is 5 s; a
# multi-MB pasted prompt with greedy `.*` patterns can burn all of it and
# silently skip enforcement. 16 KiB is more than enough context to detect a
# leading ```kcl block, a .kcl filename, or an md↔kcl translation intent.
PROMPT=$(printf '%s' "$PROMPT" | head -c 16384)

NUDGE=""

# Fenced ```kcl code block → kcl-read
if printf '%s' "$PROMPT" | grep -qE '```[[:space:]]*kcl'; then
  NUDGE+="A \`\`\`kcl fenced block is present in the user prompt. Invoke the khala:kcl-read skill to decode it before answering.\n"
fi

# Inline KCL markers (§ sections, Δ deltas, [TAG|slot:val] frames) → kcl-read
if printf '%s' "$PROMPT" | grep -qE '§[A-Z_]+|Δ\[|\[[A-Z_]+\|'; then
  NUDGE+="Inline KCL markers (§, Δ, or [TAG|...]) appear in the prompt. Invoke khala:kcl-read to interpret them.\n"
fi

# Mention of a .kcl file path → kcl-read
if printf '%s' "$PROMPT" | grep -qE '[[:alnum:]_./-]+\.kcl\b'; then
  NUDGE+="The prompt references a .kcl file. Invoke khala:kcl-read to load it; do not Read it raw.\n"
fi

# Translation intent (md ↔ kcl)
if printf '%s' "$PROMPT" | grep -qiE '(md|markdown).*(to|->|→|into).*kcl|kcl.*(to|->|→|into).*(md|markdown)|translate.*kcl|convert.*kcl'; then
  NUDGE+="Translation intent detected. Invoke khala:kcl-translate — it preserves the filename stem and handles both directions.\n"
fi

# Encode/document/save-as-KCL intent
if printf '%s' "$PROMPT" | grep -qiE '(write|save|document|record|encode|capture).*(as|in|to)? *kcl'; then
  NUDGE+="The user wants to encode content as KCL. Invoke khala:kcl-write — it loads the bootstrap and emits a spec-compliant .kcl file.\n"
fi

if [[ -z "$NUDGE" ]]; then
  exit 0
fi

jq -nc --arg ctx "$NUDGE" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
