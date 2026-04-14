# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Nature

This repository contains **specification documents only** — no source code, build system, tests, or package manifests. It defines **KCL (Khala Context Language) v0.1**, a structured encoding language for compressing LLM context windows by 5–8× with <1% semantic fidelity loss.

- `specs/KCL-SPEC-v0.1.md` — the full normative specification (~30KB).
- `specs/KCL-BOOTSTRAP-v0.1.md` — a two-stage self-teaching loader (Stage 1 teaches KCL in ~700 tokens; Stage 2 delivers the full spec expressed in KCL in ~1,500 tokens; ~2,200 tokens combined).
- `LICENSE` — CC-BY-4.0 license text.

There are no commands to run. Work in this repo is editing markdown specs.

## Architecture of the Specification

KCL is organized into a **four-tier encoding model**. When editing specs, preserve this structure — changes to one tier's syntax usually propagate to grammar, symbol tables, and bootstrap text.

| Tier | Block Forms | Purpose |
|------|-------------|---------|
| -1 | `§TRUST{...}`, `§FACT✓[...]`, `§CLAIM~[...]` | Epistemic state / trust levels |
| 0 | `§META`, `§ONTO`, `§TOOLS`, `§USE` | Session metadata, ontology, tools, domain packs |
| 1 | `[TAG \| slot:val, ...]` | Structured semantic frames (the main content) |
| 2 | `Δ[ref \| key:old→new, ⊕key:val, ⊖key]` | Delta encoding for incremental state |

Cross-cutting mechanisms: `§CHECKPOINT{...}` (drift prevention), `§COMPRESS{...}` (adaptive compression levels), `§HISTORY{...}` (turn-range summaries), `§NL["..."]` (NL escape hatch), `@directive(args)` (commands to the model).

## Conventions Specific to KCL Specs

- **Pipe separator ambiguity:** inside KCL frames the separator is ASCII `|` (U+007C). The glyph `∣` (U+2223) is used **only inside markdown tables** to avoid breaking table rendering. Do not mix them in executable/example KCL; both specs state this explicitly.
- **Reserved symbols** are drawn from math/code/markup Unicode blocks so LLMs parse them zero-shot. When adding symbols, prefer ones already frequent in pretraining corpora rather than inventing new ones.
- **Bootstrap duality:** `KCL-SPEC` is the normative source; `KCL-BOOTSTRAP` is a compressed, self-describing restatement. Any semantic change to the spec must be reflected in the bootstrap's Stage 2 KCL block, and vice versa — they are kept token-budget-tight (~2,200 tokens combined target).
- **Grammar is pseudo-BNF**, not machine-enforced. Keep grammar, symbol tables, and worked examples in sync by hand.
- Spec version and date appear in multiple places (`§META{kcl:..., date:...}`, header frontmatter, footer). Update all occurrences together.

## Authorship

Specs credit Chiro <chiro[at]orochi.network> with a "Multi-Agent Collaborative Design Panel" as co-authors. The panel refers to the specific LLMs used to evaluate experimental results and iterate the spec toward zero-shot parseability: **Gemma 4, Qwen 3.5, Claude Opus 4.6, and Nemotron 3**. Preserve this multi-model framing when editing headers — it is load-bearing for the cross-model compatibility claims (see `[BENCHMARKS|zero_shot_targets]` in the bootstrap).
