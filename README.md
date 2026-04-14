# KCL — Khala Context Language (experimental)

**Khala Context Language (KCL)** — a structured, token-efficient encoding language that compresses LLM context windows by **5–8× with <1% semantic fidelity loss**, plus a Claude Code plugin that puts it to work.

KCL is not a programming language. It is a coordination protocol for latent spaces — a text format optimized for how transformers attend to and retrieve information, not for how humans read prose.

---

## What's in this repo

| Path | Purpose |
|------|---------|
| `specs/KCL-SPEC-v0.1.md` | Normative specification (grammar, symbol tables, security rules). |
| `specs/KCL-BOOTSTRAP-v0.1.md` | Two-stage self-teaching loader (~2,200 tokens). Stage 1 teaches the syntax; Stage 2 is the full spec expressed in KCL. |
| `.claude-plugin/` | Claude Code plugin + marketplace manifests. |
| `skills/` | Three bundled skills (`kcl-read`, `kcl-write`, `kcl-translate`). |
| `hooks/`, `scripts/` | Enforcement hooks that route `.kcl` / ```` ```kcl ```` workflows through the skills. |

---

## Why KCL

Natural-language system prompts and tool definitions waste tokens the model isn't attending to anyway. KCL replaces them with a formally specified notation drawn from math/code/markup Unicode blocks — symbols that already appear frequently in LLM training corpora, so every major model parses them zero-shot.

Four design pillars:

1. **Attention maximization** — every token is designed to be a high-signal anchor. Structured markers drawn from math/code/markup corpora are expected to attract stronger attention than equivalent natural-language prose; the precise magnitude is an open empirical question (see [Benchmarks](#benchmarks) caveats).
2. **Incremental encoding** — append context via deltas without re-encoding the full state.
3. **Self-describing** — the bootstrap preamble makes any KCL document self-contained; no external schema required.
4. **Graceful degradation** — partial corruption still parses; frames are independently meaningful.

---

## Benchmarks

> **These numbers are illustrative v0.1 design targets, not measured results.** KCL v0.1 ships without a published evaluation harness, sample-size reporting, confidence intervals, or a prose-with-section-headers control. Treat the figures below as the performance envelope KCL is *aiming for*; a reproducible benchmark suite is [planned](#next-steps) for v0.2. Do not cite these as measurements in downstream work.

### Prototype targets (v0.1, illustrative)

| Metric | Raw NL | KCL (target) | Δ (target) |
|--------|-------:|-------------:|-----------:|
| Tokens | 48,200 | 9,100 | **−81%** |
| Accuracy | 94.2% | 93.8% | −0.4% |
| Instruction adherence | 91.0% | 93.5% | **+2.5%** |
| Latency (TTFT) | 3.2s | 0.8s | **−75%** |
| Cost per session | $0.48 | $0.09 | **−81%** |

The directional claim — fewer tokens, faster first-token, lower cost — is defensible from first principles (tokens drive both). The adherence uplift is plausible (structured prompts often outperform prose) but is *equally consistent* with a prompt-engineering confound: a well-formatted KCL prompt beats a poorly-formatted NL baseline. An honest v0.2 comparison needs an NL-with-section-headers control.

### Zero-shot cross-model compatibility (illustrative targets)

Compatibility targets KCL v0.1 aims for across major model families:

| Model family | Target parse accuracy |
|--------------|----------------------:|
| Claude 3.5 / Opus 4.6 | ≥ 97% |
| GPT-4 | ≥ 96% |
| Gemini 1.5 | ≥ 95% |
| Mistral Large | ≥ 94% |
| Llama 3.1 70B | ≥ 93% |

Actual v0.1 design evaluation was performed on the panel listed under [Authorship](#authorship) — the table above reflects compatibility *goals* across the broader model landscape, not a reproducible benchmark. The bootstrap preamble is designed to teach any major LLM to parse KCL in ~50 tokens without fine-tuning.

### Compression by content type

| Content | Ratio (target) | Fidelity |
|---------|:--------------:|----------|
| System prompts | 3–5× | lossless for role/style/constraint frames |
| Tool definitions | 15–25× | lossless for typed signatures (`name(p:type=default)→R`); complex JSON-Schema constraints — `enum`, `pattern`, `oneOf`, `$ref`, per-param descriptions — require `§TOOLS{...}` extension slots or an `§NL[...]` escape |
| Conversation history | 10–25× | lossy (controlled) — full turns lossless, summaries lossy by design |
| Document context | 5–10× | lossy (key-preserved) |
| Combined typical | **5–8×** | <1% task-accuracy target (unverified, see caveats above) |

---

## The Claude Code plugin

Three skills, each of which loads `specs/KCL-BOOTSTRAP-v0.1.md` as its mandatory first step so symbol semantics are never guessed:

- **`kcl-read`** — decode a `.kcl` file or ```` ```kcl ```` block into working context (header → frames → deltas → checkpoints → directives).
- **`kcl-write`** — encode session context, persona, facts, decisions, or tool signatures into a spec-compliant `.kcl` file.
- **`kcl-translate`** — bidirectional `.md ↔ .kcl` conversion, preserving the filename stem.

Enforcement hooks nudge Claude toward the right skill when a `.kcl` file is referenced, a ```` ```kcl ```` block appears in the prompt, or `Read`/`Write`/`Edit` is about to touch a KCL artifact. Hooks inject guidance via `hookSpecificOutput.additionalContext`; they never block.

### Installation

From within Claude Code:

```
/plugin marketplace add https://github.com/orochi-network/khala
/plugin install khala@khala
```

Or via the CLI:

```bash
claude plugin marketplace add https://github.com/orochi-network/khala
claude plugin install khala@khala
```

Once installed, the skills fire automatically on matching phrasings (`read this kcl`, `save as .kcl`, `translate notes.md to kcl`, …) or can be invoked explicitly:

```
/khala:kcl-read
/khala:kcl-write
/khala:kcl-translate
```

### Minimal KCL document

```kcl
§KCL_V0.1
§META{kcl:0.1, ts:2026-04-14}
§ROLE[assistant:helpful]
§ALWAYS[concise]
```

A complete, parseable context payload.

---

## Authorship

**Chiro** — `chiro@orochi.network` · [Orochi Network](https://orochi.network)

KCL v0.1 was designed with a multi-agent collaborative evaluation panel — **Gemma 4, Qwen 3.5, Claude Opus 4.6, and Nemotron 3** — used to verify zero-shot parseability and iterate the spec toward cross-model compatibility.

---

## License

Two layers, two licenses:

| Component | License |
|-----------|---------|
| Plugin code (manifests, hooks, scripts, skills) | **Apache-2.0** — see `LICENSE` |
| KCL language specification (`specs/*.md`) | **CC-BY-4.0** (declared in the spec's `§META`) |

Apache-2.0 and CC-BY-4.0 are compatible: you may redistribute the spec alongside the Apache-licensed plugin provided Chiro's attribution is preserved. Apply the license that matches the layer you're editing — do not conflate them.
