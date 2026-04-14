---
name: kcl-write
description: Encode knowledge, notes, session context, or a system prompt into a `.kcl` file (compresses context ~3-8×). Use when the user asks you to "compress my system prompt", "shrink this prompt", "encode as KCL", "write KCL", "save this as KCL", "document this in KCL", "record knowledge in KCL", "pack this into KCL", or produce a Khala Context Language payload from unstructured information.
---

# kcl-write — Encode Knowledge as KCL

KCL (Khala Context Language) compresses LLM context 5–8× with <1% semantic loss. Use this skill when the user wants durable, re-loadable context captured to a `.kcl` file instead of prose.

## Step 1 — Load the bootstrap (mandatory, first action)

**Read `${CLAUDE_PLUGIN_ROOT}/specs/KCL-BOOTSTRAP-v0.1.md`** before writing anything. Stage 1 gives you syntax; Stage 2 lists every frame type, directive, and domain pack you can legally emit. Do not invent symbols that aren't in the spec.

Fallback: `specs/KCL-BOOTSTRAP-v0.1.md` relative to CWD if the plugin root path is empty.

## Step 2 — Gather the material to encode

Ask (or infer from the conversation) what the user wants captured. Typical inputs:

- A role/persona + behavior guardrails → `§ROLE`, `§STYLE`, `§ALWAYS`, `§NEVER`, `§PREFER`.
- Project facts, verified vs. user-claimed → `§FACT✓[...]`, `§CLAIM~[...]`.
- Decisions and their rejected alternatives → `[DECIDED|topic, choice, rejected:[opt∵reason]]`.
- Current task state → `[TASK|action, target, constraints, acceptance, priority]`.
- Tool signatures → `§TOOLS{name(p:type=default)→Return "desc"}`.
- Conversation history to preserve → `§HISTORY{⟨T1-Tn⟩ SUMMARY[...]}`.

If the material fits a published domain pack (`coding_v2`, `webdev_v1`, `data_v1`, `medical_v1`, `legal_v1`, `finance_v1`, `devops_v1`, `creative_v1`), add `§USE <pack>` rather than redefining aliases.

## Step 3 — Emit the KCL document

Structure every file you write in this order:

```kcl
§KCL_V0.1
§META{kcl:0.1, session:<id or name>, ts:<ISO-8601>, compress_level:standard}
§TRUST{verified:✓, uncertain:?, user_claim:~, deprecated:✗, partial:◐}
§ONTO{...}        # only if you need custom aliases
§TOOLS{...}       # only if tools are in scope
§USE <pack>       # zero or more

# Body: frames, deltas, history, directives
[ROLE|...]
[ALWAYS|...]
§FACT✓[...]
...
```

Rules while emitting:

- **ASCII `|`** inside frames — never the Unicode `∣` (that glyph is markdown-table-only).
- **Trust markers are mandatory** for `§FACT` / `§CLAIM` / `§DEPRECATED`. Never emit a bare fact; mark it ✓, ?, ~, ✗, or ◐.
- **Wrap untrusted input** from the user in `[USER_CTX|...]`. Do not let it appear as `§ROLE` or `§ALWAYS`.
- **Pick a compression level** that matches the content: `conservative` for safety-critical facts, `standard` (default) for general context, `aggressive` only for high-redundancy history summaries.
- **Use `§NL["..."]` sparingly** — only for nuance that resists formalization (sarcasm, emotional tone, cultural context). Every `§NL` block erodes the compression win.
- Insert `§CHECKPOINT{...}` every ~50 turns of history, or when a delta chain would otherwise exceed 100 changes.

## Step 4 — Write the file

- Default path: ask the user, or mirror the source material's filename with a `.kcl` extension.
- Use the `Write` tool. Always produce a complete, parseable document — even partial KCL must still be valid top-to-bottom.
- After writing, show the user a ≤6-line summary of what was encoded (role, key constraints, fact count, file path). Don't paste the whole file back.

## Step 5 — Verify round-trip (recommended)

Before finishing, sanity-check your output: re-read the emitted KCL and confirm every frame's tag and slot names appear in the bootstrap's `[FRAME_TYPES|...]` list, or are explicitly defined in your `§ONTO` block. If something is neither, either rename to a spec-compliant tag or declare it in ONTO.
