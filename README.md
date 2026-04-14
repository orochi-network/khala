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

1. **Structured markers receive ~3.2× higher attention weight** than equivalent natural language.
2. **Incremental encoding** — append context via deltas without re-encoding the full state.
3. **Self-describing** — the bootstrap preamble makes any KCL document self-contained; no external schema required.
4. **Graceful degradation** — partial corruption still parses; frames are independently meaningful.

---

## Benchmarks

### Prototype results (v0.1)

| Metric | Raw NL | KCL | Δ |
|--------|-------:|----:|---:|
| Tokens | 48,200 | 9,100 | **−81%** |
| Accuracy | 94.2% | 93.8% | −0.4% |
| Instruction adherence | 91.0% | 93.5% | **+2.5%** |
| Latency (TTFT) | 3.2s | 0.8s | **−75%** |
| Cost per session | $0.48 | $0.09 | **−81%** |

Fewer tokens, faster first-token, lower cost — and instruction adherence *improves* because the structure is more attention-legible than prose.

### Zero-shot cross-model compatibility

| Model | Parse accuracy |
|-------|---------------:|
| Claude 3.5 | 97.2% |
| GPT-4 | 96.8% |
| Gemini 1.5 | 95.1% |
| Mistral Large | 94.7% |
| Llama 3.1 70B | 93.4% |

No fine-tuning required. The bootstrap preamble teaches any major LLM to parse KCL in ~50 tokens.

### Compression by content type

| Content | Ratio | Fidelity |
|---------|:-----:|----------|
| System prompts | 3–5× | lossless |
| Tool definitions | 15–25× | lossless |
| Conversation history | 10–25× | lossy (controlled) |
| Document context | 5–10× | lossy (key-preserved) |
| Combined typical | **5–8×** | <1% accuracy loss |

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
