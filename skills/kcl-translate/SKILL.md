---
name: kcl-translate
description: Translate between Markdown and KCL. Use when the user asks to "translate md to kcl", "convert this markdown to KCL", "turn this .kcl into markdown", "md → kcl", "kcl → md", or provides a `<name>.md` / `<name>.kcl` file and wants the other format produced with the same filename stem.
---

# kcl-translate — Bidirectional .md ↔ .kcl Conversion

This skill converts between plain Markdown and KCL (Khala Context Language) while **preserving the filename stem**. `notes.md` → `notes.kcl`; `session.kcl` → `session.md`.

## Step 1 — Load the bootstrap (mandatory, first action)

**Read `${CLAUDE_PLUGIN_ROOT}/specs/KCL-BOOTSTRAP-v0.1.md`** first. You cannot translate correctly without the full symbol table, frame catalogue, and tier semantics.

Fallback: `specs/KCL-BOOTSTRAP-v0.1.md` relative to CWD.

## Step 2 — Detect direction and output path

Infer the direction from the input file's extension:

| Source extension | Direction       | Output extension |
|------------------|-----------------|------------------|
| `.md`            | md → kcl        | `.kcl`           |
| `.kcl`           | kcl → md        | `.md`            |

Output path = same directory, same stem, swapped extension. Examples:

- `/home/u/specs/KCL-SPEC-v0.1.md` → `/home/u/specs/KCL-SPEC-v0.1.kcl`
- `./notes/session.kcl` → `./notes/session.md`

If the user gave an ambiguous input (a raw code block, no filename), ask them for a target stem before writing.

## Step 3a — Markdown → KCL

Strategy: the Markdown is the source of truth; KCL is the compressed restatement. Do not drop information — move it into the right tier.

1. **Front matter / metadata blocks** (YAML frontmatter, title, date, author, version) → `§META{...}`.
2. **Document-level claims or definitions** (status, license, spec version) → `§FACT✓[...]` if authoritative, `§CLAIM~[...]` if unverified.
3. **Normative lists and tables** → frames. A table row with columns `(name, type, description)` becomes `[ROW|name:..., type:..., desc:"..."]`. Repeat per row; don't flatten into prose.
4. **Persona / role / style guidance** (common in system-prompt-style docs) → `§ROLE`, `§STYLE`, `§ALWAYS`, `§NEVER`, `§PREFER`.
5. **Grammar, BNF, symbol tables, enum definitions** → `§ONTO{types:{...}}` when they're reusable, or a dedicated `[GRAMMAR|...]` frame when they're document-local.
6. **Prose that can't be formalized** (rationale, narrative, nuance) → `§NL["..."]`. Use sparingly; condense first.
7. **Headings** become tags on surrounding frames (e.g. `## Security` → group frames under `[SECURITY|...]`). Do not emit headings as frames themselves — KCL has no heading primitive.

Emit the standard header in order: `§KCL_V0.1` → `§META` → `§TRUST` → `§ONTO?` → `§TOOLS?` → `§USE*` → body. Use ASCII `|` inside frames.

## Step 3b — KCL → Markdown

Strategy: expand the compressed form into readable prose while preserving every frame's information. The Markdown need not be terse — readability > compression in this direction.

1. **`§META`** → YAML frontmatter or a "Metadata" section at the top.
2. **`§TRUST`, `§ONTO`, `§TOOLS`** → render as labeled markdown tables (each has a natural table shape: marker→meaning, alias→expansion, tool→signature).
3. **Frames** → render each as either a short paragraph (`**TAG.**  slot1 is X, slot2 is Y.`) or a bullet list, whichever reads better for the frame's tag. Keep the TAG as a bold lead-in so the structure survives.
4. **Deltas (`Δ[...]`)** → render as a narrated change list ("**Change to #ref:** `key` went from `old` to `new`; added `⊕key:val`; removed `⊖key`."). Apply them to the referenced frame if inlining makes the doc clearer.
5. **`§HISTORY`** → a "History" section. Summaries become paragraph summaries; full turns become blockquotes with the actor prefix.
6. **`§CHECKPOINT`** → a horizontal rule + "## Checkpoint" heading; render the body as a full snapshot.
7. **`§NL["..."]`** → pass through as plain prose, unquoted.
8. **Directives (`@...`)** → a short "Directives" section listing them with their meanings.

## Step 4 — Write the output file and confirm

- Use the `Write` tool. Path = computed in Step 2.
- After writing, report: source path → target path, direction, approximate token ratio (`md → kcl` should typically compress 3–8×; `kcl → md` typically expands 3–8×). Under 5 lines.
- Do not delete or overwrite the source unless the user explicitly asks.

## Fidelity rules

- **Lossless when possible.** System prompts and tool definitions must round-trip without semantic drift. Verify mentally that a `md → kcl → md` cycle would preserve every normative claim.
- **Lossy is allowed for history summaries and document prose**, but never silently. Add a `§NL["..."]` note or a `> Note:` blockquote flagging what was compressed.
- **Never invent trust markers.** If the Markdown doesn't say whether a fact is verified, use `?` (uncertain), not `✓`.
- **Never translate `§NL["..."]` contents as KCL.** They are opaque prose; carry them verbatim.
