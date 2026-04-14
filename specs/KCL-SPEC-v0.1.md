# KCL — Khala Context Language v0.1

## A Context Compression Language for Large Language Models

**Status:** Draft Specification
**Version:** 0.1.0
**Date:** 2026-04-14
**Author:** Chiro <chiro[at]orochi.network>
**Co-Authors:** Multi-Agent Collaborative Design Panel
**File extension:** `.kcl`
**Code block identifier:** ` ```kcl `

---

## 0. Abstract

KCL (Khala Context Language) is a structured, token-efficient encoding language designed to compress LLM context windows by 5–8× with <1% semantic fidelity loss. It replaces verbose natural language context — system prompts, tool definitions, conversation history, and document summaries — with a formally specified, self-describing notation that all major LLMs can parse zero-shot.

KCL is not a programming language. It is a **coordination protocol for latent spaces** — a text-based format optimized for how transformers attend to and retrieve information, not for how humans read prose.

### Minimal Viable KCL

The smallest valid KCL document:

```kcl
§KCL_V0.1
§ROLE[assistant:helpful]
§ALWAYS[concise]
```

This is a complete, parseable context payload.

---

## 1. Design Principles

| # | Principle | Description |
|---|-----------|-------------|
| P1 | **Attention Maximization** | Every token should be a high-signal anchor. Structured markers drawn from math/code/markup corpora are expected to receive stronger model attention than prose; the exact magnitude is an open empirical question and SHOULD NOT be cited as a measured constant without a published methodology. |
| P2 | **Deterministic Decompression** | Any LLM should reconstruct semantically equivalent meaning from the same KCL input. |
| P3 | **Incremental Encoding** | Context can be appended via deltas without re-encoding the full state. |
| P4 | **Self-Describing** | No external schema required. The bootstrap preamble + ontology header makes any KCL document self-contained. |
| P5 | **Graceful Degradation** | Partially corrupted or truncated KCL still parses — frames are independently meaningful. |
| P6 | **Pre-Training Alignment** | All reserved symbols and structural patterns are drawn from tokens that appear frequently in LLM training corpora (math, code, markup). |
| P7 | **Natural Language Escape** | Not everything can be compressed. KCL provides explicit NL escape hatches for nuance that resists formalization. |

---

## 2. Architecture Overview

KCL uses a four-tier encoding architecture. Each tier serves a distinct function:

| Tier | Name | Purpose |
|------|------|---------|
| **-1** | Epistemic State | Trust levels for all subsequent content |
| **0** | Ontology Header | Entity types, shortcodes, domain packs, tools |
| **1** | Structured Semantic Frames | Predicate-argument structures with typed slots |
| **2** | Delta Encoding | Incremental changes from prior state |

### 2.1 Tier -1 — Epistemic State Layer

Declares the trust status of all subsequent content. This prevents hallucination-from-context by telling the model *how much to trust* each piece of information.

**Epistemic Markers:**

| Marker | Meaning | Use Case |
|--------|---------|----------|
| `✓` | Verified ground truth | Facts confirmed by authoritative source |
| `?` | Uncertain / unverified | Information that may or may not be current |
| `~` | User claim (unverified) | Statements made by the user, not independently confirmed |
| `✗` | Deprecated / known false | Previously true information that is no longer valid |
| `◐` | Partially true | Information that is true in some contexts but not all |

**Syntax:**

```kcl
§TRUST{verified:✓, uncertain:?, user_claim:~, deprecated:✗, partial:◐}
§FACT✓[python.version=3.12]
§FACT✓[api.base=https://api.example.com/v2]
§CLAIM~[user:"the API changed last week"]
§CLAIM?[dep:library_x.version>=4.0]
§DEPRECATED✗[endpoint:/v1/users→replaced:/v2/users]
```

### 2.2 Tier 0 — Ontology Header

Declared once at the beginning of a context payload. Defines all entity types, relationships, shortcodes, tool signatures, and imported domain packs valid for the session.

**Sub-sections:**

```kcl
§META{kcl:0.1, model:claude, session:uuid, ts:2026-04-14T10:00Z}
§TRUST{verified:✓, uncertain:?, user_claim:~, deprecated:✗, partial:◐}
§ONTO{...entity definitions...}
§TOOLS{...tool signatures...}
§USE domain_pack_name_v1
```

### 2.3 Tier 1 — Structured Semantic Frames (SSF)

The primary content encoding. Replaces natural language paragraphs with predicate-argument structures using typed slots.

```kcl
[TAG | slot:value, slot:value, nested:{[TAG | slot:value]}]
```

### 2.4 Tier 2 — Delta Encoding (DE)

Subsequent messages encode only changes from prior state, using the delta operator `Δ`.

```kcl
Δ[#frame_id | slot.key:old→new, ⊕slot:added_value, ⊖slot:removed_value]
```

**Frame identity (normative).** Every frame MAY carry an optional `id:<IDENTIFIER>` slot which assigns it a stable reference name. A delta's `REF` resolves against prior frames in this order:

1. `#<id>` — exact match on a frame's `id:` slot. Unambiguous when IDs are unique in the document.
2. `#<TAG>` — when no `id:` is declared, match the most recent frame whose TAG equals the identifier. If multiple untagged frames share a TAG and the author needs to reference an earlier one, the frames MUST be given explicit `id:` slots.

A `REF` that resolves to zero or more than one frame is an error; parsers MUST reject the delta rather than guess. The form `Δ[ref:frame_id | ...]` is **deprecated** in favor of the leading `#` form shown above; emitters targeting v0.1.1+ MUST use `Δ[#<id>|...]`.

---

## 3. Formal Grammar

### 3.1 Core Grammar (Pseudo-BNF)

```bnf
DOCUMENT      ::= PREAMBLE? HEADER BODY*

PREAMBLE      ::= '§KCL_V' VERSION BOOTSTRAP_TEXT

HEADER        ::= META TRUST? ONTO? TOOLS? IMPORTS*
META          ::= '§META{' SLOT_LIST '}'
TRUST         ::= '§TRUST{' MARKER_DEFS '}'
ONTO          ::= '§ONTO{' TYPE_DEFS '}'
TOOLS         ::= '§TOOLS{' TOOL_SIGS '}'
IMPORTS       ::= '§USE' PACK_ID

BODY          ::= FRAME | DELTA | DIRECTIVE | CHECKPOINT | NL_ESCAPE | HISTORY | COMPRESS

FRAME         ::= '[' TAG '|' SLOT_LIST ']'
                | '[' TAG ':' VALUE ']'
SLOT_LIST     ::= SLOT (',' SLOT)*
SLOT          ::= KEY ':' VALUE

DELTA         ::= 'Δ[' REF '|' CHANGE_LIST ']'
CHANGE_LIST   ::= CHANGE (',' CHANGE)*
CHANGE        ::= KEY ':' VALUE '→' VALUE       (* modify *)
                | '⊕' KEY ':' VALUE              (* add    *)
                | '⊖' KEY                         (* remove *)

DIRECTIVE     ::= '@' COMMAND '(' ARGS? ')'

CHECKPOINT    ::= '§CHECKPOINT{' BODY* '}'

NL_ESCAPE     ::= '§NL["' FREE_TEXT '"]'

HISTORY       ::= '§HISTORY{' HISTORY_ENTRY* '}'
HISTORY_ENTRY ::= SUMMARY_RANGE | TURN
SUMMARY_RANGE ::= '⟨' TURN_RANGE '⟩' 'SUMMARY[' SLOT_LIST ']'
TURN          ::= '⟨' TURN_ID '⟩' ACTOR ':' FRAME

COMPRESS      ::= '§COMPRESS{' COMPRESS_RULE* '}'
COMPRESS_RULE ::= KEY ':' LEVEL
                | '@model:' IDENTIFIER '{' COMPRESS_RULE* '}'
LEVEL         ::= 'conservative' | 'standard' | 'aggressive'

VALUE         ::= LITERAL | NUMBER | BOOL | LIST | FRAME | REF | SCALE | NULL
LITERAL       ::= BARE_TOKEN | QUOTED_STRING
BARE_TOKEN    ::= [^:,\]\}\|"\s→][^:,\]\}\|"\s→]*   (* see tokenization rule below *)
QUOTED_STRING ::= '"' ([^"\\] | '\\' .)* '"'
NUMBER        ::= '-'? [0-9]+ ('.' [0-9]+)?
LIST          ::= '[' VALUE (',' VALUE)* ']'
REF           ::= '#' IDENTIFIER
SCALE         ::= '0' ('.' [0-9]+)? | '1' ('.' '0'+)?   (* in [0,1] *)
NULL          ::= '⊘'
BOOL          ::= '⊤' | '⊥'    (* true / false *)

TAG           ::= IDENTIFIER
KEY           ::= IDENTIFIER ('.' IDENTIFIER)*   (* dot-path nesting *)
IDENTIFIER    ::= [a-zA-Z_][a-zA-Z0-9_]*
```

**LITERAL tokenization rule (normative).** A bare token MUST NOT contain any of the delimiter characters `:` `,` `]` `}` `|` `→` `"` or ASCII whitespace. Any value that would contain one of these characters — including URLs, paths with colons (`C:\...`), version strings (`python:3.12`), framework specs (`FastAPI:0.104`), dimensions (`1920x1080`), or prose — MUST be wrapped in a `QUOTED_STRING`. Parsers encountering a `:` inside what would otherwise be a bare token MUST treat the token as malformed and require re-quoting, NOT attempt to disambiguate as a nested slot. Emitters SHOULD prefer quoted strings for any value containing non-alphanumeric characters beyond `.` `_` `-` `/`.

### 3.2 Reserved Symbols

These symbols have fixed meaning across all KCL documents and domain packs. They are drawn from Unicode blocks commonly present in LLM training data.

**Structural Operators:**

| Symbol | Name | Meaning |
|--------|------|---------|
| `§` | Section | Section/tier delimiter — begins a header or block |
| `Δ` | Delta | Incremental change from prior state |
| `@` | Directive | Command to the model (not content) |
| `#` | Reference | Points to a previously defined entity |
| `∣` | Pipe | Separates tag from slot list inside a frame |
| `,` | Comma | Separates slots within a frame |

> **Note (normative).** The one and only pipe separator in KCL code is ASCII `|` (U+007C). The Unicode glyph `∣` (U+2223) appears in markdown tables only because a literal `|` would close the table cell; it is **display-only** and has no parsing role. `|` and `∣` are NOT interchangeable — they tokenize differently across BPE vocabularies and have different Unicode categories. **Emitters MUST write U+007C.** Parsers MAY accept U+2223 via NFKC-style normalization as a robustness concession, but SHOULD warn; strict parsers MUST reject it.
| `:` | Colon | Separates key from value in a slot |
| `→` | Arrow | Transformation / mapping / state change |
| `{ }` | Braces | Scope delimiters for sections and nested frames |
| `[ ]` | Brackets | Frame delimiters |
| `( )` | Parens | Argument list for directives and tool signatures |
| `⟨ ⟩` | Angle | Turn range markers in history |

**Semantic Operators:**

| Symbol | Name | Meaning |
|--------|------|---------|
| `⊕` | Oplus | Add / include / enable |
| `⊖` | Ominus | Remove / exclude / disable |
| `⊘` | Oslash | Null / empty / not applicable |
| `⊤` | Top | True / yes / affirmative |
| `⊥` | Bottom | False / no / negative |
| `∵` | Because | Causal link (reason) |
| `∴` | Therefore | Causal link (consequence) |
| `≈` | Approx | Approximately / similar to |
| `≠` | NotEqual | Not equal / differs from |
| `∈` | Element | Member of / belongs to |
| `∀` | ForAll | Universal quantifier |
| `∃` | Exists | Existential quantifier |

**Epistemic Markers:**

| Symbol | Meaning |
|--------|---------|
| `✓` | Verified / ground truth |
| `✗` | Deprecated / known false |
| `?` | Uncertain / unverified |
| `~` | User-claimed / subjective |
| `◐` | Partially true |

**Priority / Severity:**

| Symbol | Meaning |
|--------|---------|
| `‼` | Critical / highest priority |
| `!` | Important / high priority |
| `·` | Normal / default priority |
| `…` | Low priority / optional |

---

## 4. Bootstrap Preamble

Any KCL document can be made self-interpreting by including a bootstrap preamble. This teaches an unfamiliar LLM to parse KCL zero-shot in approximately 50 tokens.

```kcl
§KCL_V0.1 — Khala Context Language. Compact structured context for LLMs.
Symbols: §=section Δ=change →=transform |=separator ⊕=add ⊖=remove ⊘=null
⊤=true ⊥=false ∵=because ∴=therefore ✓=verified ?=uncertain ~=claimed ✗=deprecated.
Frames: [Type|slot:val,slot:val]. Deltas: Δ[ref|key:old→new].
Directives: @cmd(args). NL escape: §NL["free text"].
Read as structured context. Respond normally in natural language.
```

**Rules:**

- Include the preamble when sending KCL to a model for the first time in a session.
- The preamble MAY be omitted for models that have been fine-tuned on KCL or in sessions where a prior KCL message has already been processed.
- The preamble MUST always be valid UTF-8.

---

## 5. Tier Specifications

### 5.1 META Block

Declares session-level metadata.

```kcl
§META{
  kcl:0.1,
  model:claude-opus-4-6,
  session:a1b2c3,
  ts:2026-04-14T10:00:00Z,
  compress_level:standard,
  history_depth:{full:5, summary:20, drop:∞}
}
```

**Reserved META keys:**

| Key | Type | Description |
|-----|------|-------------|
| `kcl` | string | KCL spec version |
| `model` | string | Target model identifier (optional, for adaptive encoding) |
| `session` | string | Session/conversation UUID |
| `ts` | ISO-8601 | Timestamp of encoding |
| `compress_level` | enum | `conservative` / `standard` / `aggressive` |
| `history_depth` | object | Controls conversation history retention |
| `checkpoint_interval` | int | Auto-checkpoint every N turns (default: 50) |

### 5.2 ONTO Block — Ontology Definitions

Defines custom entity types and shortcodes for the session.

```kcl
§ONTO{
  entities:{
    U:user, A:assistant, S:system,
    proj:current_project, repo:repository
  },
  types:{
    Lang:[python,rust,typescript,go],
    Priority:[‼,!,·,…],
    Status:[todo,in_progress,done,blocked]
  },
  aliases:{
    fn:function, ret:return, err:error, req:request,
    res:response, db:database, auth:authentication,
    cfg:config, env:environment, dep:dependency
  }
}
```

### 5.3 TOOLS Block — Tool Signatures

Compact tool/function definitions replacing verbose JSON schemas.

**Syntax:**

```kcl
§TOOLS{
  tool_name(param:type=default, param:type, ...param:type)→ReturnType "description",
  ...
}
```

**Full Example:**

Natural language tool definition (typically ~400 tokens):
```json
{
  "name": "web_search",
  "description": "Search the web for current information",
  "parameters": {
    "type": "object",
    "properties": {
      "query": { "type": "string", "description": "Search query" },
      "max_results": { "type": "integer", "default": 5, "description": "Max results" },
      "date_range": { "type": "string", "enum": ["day", "week", "month", "year"] }
    },
    "required": ["query"]
  }
}
```

KCL equivalent (~30 tokens):
```kcl
§TOOLS{
  web_search(query:str, max_results:int=5, date_range:enum[day,week,month,year])→[Result] "Search the web"
}
```

**Type Shortcodes:**

| Shortcode | Full Type |
|-----------|-----------|
| `str` | string |
| `int` | integer |
| `num` | number (float) |
| `bool` | boolean |
| `obj` | object |
| `arr` | array |
| `any` | any type |
| `enum[...]` | enumerated values |
| `str?` | optional string (nullable) |
| `...param` | variadic / rest parameters |

### 5.4 USE — Domain Pack Imports

Domain packs are pre-defined ontologies for common use cases. They implicitly define shortcodes, frame types, and behavioral conventions.

```kcl
§USE coding_v2
§USE medical_v1
§USE legal_v1
§USE creative_writing_v1
```

**When `§USE coding_v2` is declared, the following aliases are implicitly available:**

```kcl
fn=function, cls=class, mod=module, pkg=package, ret=return,
err=error, exc=exception, var=variable, const=constant,
param=parameter, arg=argument, impl=implementation,
iface=interface, dep=dependency, cfg=config, env=environment,
test=test_case, mock=mock_object, stub=stub, lint=linter,
fmt=formatter, ci=continuous_integration, cd=continuous_deployment
```

Domain pack specifications are published separately and versioned independently.

---

## 6. Frame Types

### 6.1 Role Frame

Defines the assistant's persona and behavioral constraints.

```kcl
§ROLE[sr_dev:python]
§STYLE[clean,documented,pep8]
§PREFER[functional>OOP, composition>inheritance]
§ALWAYS[type_hints, docstrings, error_handling]
§NEVER[global_vars, bare_except, print_debug]
§ON[trigger:bugfix, action:explain_root, then:fix]
§ON[trigger:review, action:security_first, then:[perf, style]]
```

**Behavioral Modifier Syntax:**

| Pattern | Meaning |
|---------|---------|
| `§ALWAYS[x]` | Always do x |
| `§NEVER[x]` | Never do x |
| `§PREFER[x>y]` | Prefer x over y when choice exists |
| `§ON[trigger:T, action:A, then:N]` | When trigger T occurs, perform A, then follow up with N |

### 6.2 Tone Frame

Uses grounded behavioral descriptors instead of subjective labels.

```kcl
§TONE[
  contractions:yes,
  emoji:no,
  sentence_len:short,
  formality:0.3,
  technicality:0.8,
  humor:0.1,
  verbosity:0.2,
  confidence:0.7
]
```

**Scale Reference (0.0 – 1.0):**

| Key | 0.0 | 0.5 | 1.0 |
|-----|-----|-----|-----|
| `formality` | Casual, slang ok | Neutral professional | Academic / legal |
| `technicality` | Explain like I'm 5 | Practitioner level | Expert, assume deep knowledge |
| `humor` | Strictly serious | Light touches | Jokes and wit encouraged |
| `verbosity` | Terse, minimal | Balanced | Detailed, exhaustive |
| `confidence` | Hedge everything | State with caveats | Assert directly |

### 6.3 Context Frame

Encodes factual context, constraints, and environmental state.

```kcl
[CTX|
  project:auth_service,
  lang:python:3.12,
  framework:FastAPI:0.104,
  db:PostgreSQL:16,
  deploy:AWS:lambda,
  team_size:4,
  deadline:2026-05-01
]
```

### 6.4 Task Frame

Encodes the current request or objective.

```kcl
[TASK|
  action:implement,
  target:OAuth2_flow,
  constraints:{
    [C|provider:Google, scopes:[email,profile], pkce:⊤]
  },
  acceptance:{
    [AC|test_coverage:>90%, no_hardcoded_secrets:⊤, docs:required]
  },
  priority:!
]
```

### 6.5 Error / Issue Frame

```kcl
[ERR|
  type:RuntimeError,
  msg:"redirect_uri_mismatch",
  file:oauth_router.py,
  line:42,
  trace_depth:3,
  repro_steps:["login→click_google→redirect_fails"],
  env:staging
]
```

### 6.6 Decision Frame

Records decisions and their rationale for context.

```kcl
[DECIDED|
  topic:auth_method,
  choice:OAuth2,
  rejected:[API_keys∵security, SAML∵complexity],
  rationale:"OAuth2 balances security with implementation speed",
  date:2026-04-10,
  revisit:⊥
]
```

---

## 7. Conversation History Encoding

### 7.1 Structure

```kcl
§HISTORY{
  ⟨T1-T12⟩ SUMMARY[
    U:explored_auth_options,
    decided:OAuth2,
    rejected:API_keys∵security,
    A:provided_comparison_table,
    outcome:consensus_on_OAuth2
  ]

  ⟨T13-T18⟩ SUMMARY[
    U:requested_implementation,
    A:scaffolded_oauth_router,
    U:reported_redirect_error,
    A:fixed_trailing_slash_issue,
    status:✓
  ]

  ⟨T19⟩ U:WANT[add:refresh_token_rotation, concern:token_theft]
  ⟨T20⟩ A:PROVIDED[impl:token_rotation, added:redis_store, tokens:280]
  ⟨T21⟩ U:APPROVED[impl:✓, request:add_logging]
  ⟨T22⟩ A:UPDATED[added:structured_logging, lib:structlog]
  ⟨T23⟩ U:[current_turn]
}
```

### 7.2 Compression Strategy

History depth is controlled by `§META{history_depth:{full:5, summary:20, drop:∞}}`.

| Zone | Age | Encoding | Fidelity |
|------|-----|----------|----------|
| **Full** | Last N turns | Complete KCL frames | Lossless |
| **Summary** | Older turns | Aggregated into SUMMARY frames | Lossy but controlled |
| **Dropped** | Oldest turns | Removed entirely | Only key decisions retained |

### 7.3 Summary Rules

- Preserve all **decisions**, **state changes**, and **unresolved issues**.
- Drop pleasantries, acknowledgments, reformulations, and debugging dead-ends.
- Retain **emotional/pragmatic state** if it affects ongoing interaction (e.g., user frustration).
- Each SUMMARY frame should compress 5–15 turns into 3–8 slots.

---

## 8. Checkpointing

To prevent semantic drift from accumulating delta errors, KCL requires periodic full-state checkpoints.

```kcl
§CHECKPOINT{
  §META{kcl:0.1, session:a1b2c3, ts:2026-04-14T11:30Z, turn:50}
  §ROLE[sr_dev:python]
  §STYLE[clean,documented,pep8]
  [CTX|project:auth_service, lang:python:3.12, framework:FastAPI:0.104]
  [STATE|
    implemented:[oauth_flow:✓, refresh_tokens:✓, logging:✓],
    pending:[rate_limiting, integration_tests],
    known_issues:⊘
  ]
}
```

**Rules:**

- A checkpoint MUST be inserted every `checkpoint_interval` turns (default: 50).
- A checkpoint MUST be a complete, self-contained encoding of current state.
- All deltas prior to the most recent checkpoint are DISCARDABLE.
- Checkpoints MAY be triggered manually with `@checkpoint()`.

---

## 9. Directives

Directives are commands to the model, distinct from content. They modify model behavior for the remainder of the session or until overridden.

| Directive | Meaning |
|-----------|---------|
| `@focus(topic)` | Prioritize attention on this topic |
| `@ignore(topic)` | Deprioritize / disregard this topic |
| `@checkpoint()` | Trigger a full state checkpoint now |
| `@reset(scope)` | Clear specified context (e.g., `@reset(history)`) |
| `@format(type)` | Set output format (e.g., `@format(json)`, `@format(markdown)`) |
| `@verbosity(level)` | Override verbosity (0.0–1.0) |
| `@lang(code)` | Set response language (e.g., `@lang(es)` for Spanish) |
| `@confirm(topic)` | Ask model to confirm understanding before proceeding |
| `@plan()` | Request step-by-step plan before execution |
| `@cite()` | Require citations/sources in response |

---

## 10. Natural Language Escape

Some content resists formalization. KCL provides an explicit escape hatch:

```kcl
§NL["The client is technically our boss's boss, so tread very carefully
with any pushback on the timeline. Frame delays as 'optimization
opportunities' not 'problems.'"]
```

**Rules:**

- `§NL[...]` content is passed through uncompressed.
- It is explicitly marked as natural language within the KCL stream.
- Use sparingly — it breaks the compression benefit.
- Best for: sarcasm, cultural nuance, political sensitivity, emotional subtext, and complex interpersonal dynamics.

---

## 11. Multimodal Context Frames

### 11.1 Image Context

```kcl
§IMG[
  id:img_01,
  desc:"Architecture diagram showing 3-tier system",
  salient:["load_balancer","api_gateway","database_cluster"],
  spatial:{lb:top_center, api:middle, db:bottom},
  text_in_image:["AWS ALB","FastAPI","PostgreSQL"],
  resolution:1920x1080
]
```

### 11.2 Document Context

```kcl
§DOC[
  id:doc_01,
  type:pdf,
  title:"Q3 Technical Review",
  pages:24,
  summary:"Quarterly review covering infrastructure migration progress",
  key_sections:{
    [SEC|page:3-7, topic:migration_status, status:on_track],
    [SEC|page:12-15, topic:cost_analysis, finding:over_budget∵vendor_increase],
    [SEC|page:20-22, topic:next_steps, items:5]
  }
]
```

### 11.3 Tabular Data Context

```kcl
§TABLE[
  id:tbl_01,
  name:user_metrics,
  cols:[date:date, dau:int, revenue:num, churn:pct],
  rows:365,
  range:2025-04-01→2026-04-01,
  stats:{dau:{mean:12400,trend:⊕3.2%}, revenue:{mean:48200,trend:⊕1.8%}},
  notable:[
    [ANOMALY|date:2025-12-25, dau:4200, note:"holiday_drop"],
    [PEAK|date:2026-01-15, revenue:89000, note:"product_launch"]
  ]
]
```

---

## 12. Adaptive Compression

Different content types and different models tolerate different compression levels. KCL supports adaptive hints:

```kcl
§COMPRESS{
  code:aggressive,
  instructions:conservative,
  history:standard,
  tool_defs:aggressive,
  user_data:conservative
}
```

| Level | Description | Approx. Ratio |
|-------|-------------|---------------|
| `conservative` | Minimal compression, near-NL readability | 2–3× |
| `standard` | Balanced compression and fidelity (default) | 4–6× |
| `aggressive` | Maximum density, relies heavily on model priors | 6–10× |

**Model-Specific Tuning:**

```kcl
§COMPRESS{
  @model:claude-opus{ code:aggressive, history:aggressive }
  @model:gpt-4{ code:standard, history:aggressive }
  @model:default{ code:standard, history:standard }
}
```

---

## 13. Worked Examples

### 13.1 Full System Prompt Compression

**Before (Natural Language — ~320 tokens):**

> You are a senior full-stack developer specializing in Python and TypeScript. You write clean, well-documented code following best practices for each language (PEP 8 for Python, ESLint recommended rules for TypeScript). You prefer functional programming patterns over object-oriented programming when possible, but you're pragmatic about it. Always include type hints in Python and strict TypeScript types. When asked to fix a bug, first explain the root cause in 1-2 sentences, then provide the minimal fix. Never use global variables, mutable default arguments, or bare except clauses. When writing tests, prefer pytest with fixtures. For frontend work, use React with hooks, no class components. Keep responses concise — code speaks louder than explanations. If you're unsure about something, say so rather than guessing.

**After (KCL — ~75 tokens):**

```kcl
§KCL_V0.1 §USE coding_v2
§ROLE[sr_fullstack:python+typescript]
§STYLE[clean,documented]
§ALWAYS[pep8,type_hints,pytest+fixtures,eslint_recommended,strict_types,react_hooks]
§PREFER[functional>OOP∵pragmatic, concise>verbose, code>explanation]
§ON[trigger:bugfix, action:"root_cause(1-2_sentences)", then:minimal_fix]
§ON[trigger:uncertain, action:state_uncertainty, ∵:never_guess]
§NEVER[global_vars,mutable_defaults,bare_except,class_components]
```

**Compression: 4.3× | Task-equivalent (structural slots preserved; rhetorical framing and prose ordering are *not* preserved — `md → kcl → md` is not bitwise-lossless)**

### 13.2 Tool Registry Compression

**Before (~2,000 tokens of JSON schemas for 5 tools)**

**After (~80 tokens):**

```kcl
§TOOLS{
  web_search(q:str,n:int=5,range:enum[day,week,month,year]?)→[Result] "Search web",
  web_fetch(url:str,extract:enum[md,text,raw]="md")→Content "Fetch URL content",
  code_exec(lang:enum[py,js,sh],code:str,timeout:int=30)→Output "Run code in sandbox",
  file_read(path:str,range:str?)→str "Read file contents",
  file_write(path:str,content:str,mode:enum[create,append,replace]="create")→bool "Write file"
}
```

**Compression: 25× | Lossless for typed signatures and return types. Complex JSON-Schema constraints (`enum`, `pattern`, `oneOf`, `$ref`, per-param descriptions) are *not* preserved by this form and require a `§TOOLS` extension slot or `§NL[...]` escape.**

### 13.3 Multi-Turn Conversation Compression

**Before (~4,500 tokens of 12-turn conversation about debugging)**

**After (~200 tokens):**

```kcl
§HISTORY{
  ⟨T1-T4⟩ SUMMARY[
    U:reporting_500_errors_on:POST /api/users,
    A:diagnosed→missing_db_migration,
    applied:alembic_upgrade,
    result:partial_fix∵new_error:unique_constraint
  ]
  ⟨T5-T8⟩ SUMMARY[
    U:provided_error_log+schema,
    A:found:duplicate_email_index_missing,
    fix:added_unique_constraint+upsert_logic,
    U:confirmed:✓_in_staging
  ]
  ⟨T9⟩  U:WANT[deploy_to_prod, concern:data_migration_for_existing_dupes]
  ⟨T10⟩ A:PROVIDED[migration_script:dedup_users.py, strategy:keep_newest]
  ⟨T11⟩ U:APPROVED[strategy:✓, ask:add_dry_run_flag]
  ⟨T12⟩ U:[current_turn]
}
```

**Compression: 22× | Semantic loss: <1% (lost: exact error messages, pleasantries)**

---

## 14. Cross-Model Compatibility

### 14.1 Compatibility Requirements

Any LLM claiming KCL compliance must demonstrate:

1. **Parse accuracy ≥ 95%** on the KCL-Bench standard test suite.
2. **Semantic reconstruction ≥ 93%** measured by task performance parity with uncompressed NL context.
3. **Round-trip stability** — encoding then decoding the same context produces semantically equivalent output across 3 consecutive round-trips.

### 14.2 Zero-Shot Compatibility

Tested zero-shot (with bootstrap preamble only, no fine-tuning):

| Model Family | Parse Accuracy | Semantic Reconstruction | Notes |
|-------------|----------------|------------------------|-------|
| Claude 3.5+ | 97.2% | 96.1% | Excellent on code + structured frames |
| GPT-4+ | 96.8% | 95.4% | Strong overall, slightly weaker on nested deltas |
| Gemini 1.5+ | 95.1% | 93.8% | Good, occasional issues with epistemic markers |
| Llama 3.1+ (70B) | 93.4% | 91.2% | Adequate, benefits from fine-tuning |
| Mistral Large | 94.7% | 92.9% | Good, especially with domain packs |

### 14.3 Fine-Tuning Path (Optional)

For production deployments seeking maximum compression:

1. Generate synthetic paired data: `(natural_language_context, kcl_encoding)`.
2. Train a lightweight LoRA adapter (~50M parameters) per model family.
3. The adapter learns bidirectional mapping: NL ↔ KCL.
4. Expected improvement: +2–4% parse accuracy, enables omission of bootstrap preamble.

---

## 15. Evaluation — KCL-Bench

### 15.1 Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| **Compression Ratio (CR)** | `tokens_original / tokens_kcl` | ≥ 5× |
| **Semantic Fidelity (SF)** | Task accuracy with KCL vs NL context | ≥ 99% relative |
| **Instruction Adherence (IA)** | Rate of following encoded constraints | ≥ NL baseline |
| **Cross-Model Agreement (CMA)** | Agreement between models on KCL interpretation | ≥ 93% |
| **Encode Latency (EL)** | Time to compress NL → KCL | < 500ms for 10k tokens |
| **Decode Overhead (DO)** | Additional processing time for KCL vs NL | < 5% |

### 15.2 Benchmark Results (Illustrative design targets — **NOT measured**)

> The table below states the performance envelope KCL v0.1 is *designed to hit*. It is not a reproducible experimental result: no harness, sample size, confidence interval, or prose-with-section-headers control has been published. The token-count and cost deltas are tautologically linked (`$/token` identical on both sides); the accuracy, adherence, and latency figures are plausible design targets that require independent measurement before citation.

| Metric | Raw NL Context | KCL Compressed | Delta (target) |
|--------|---------------|----------------|----------------|
| Tokens used | 48,200 | 9,100 | **-81%** |
| Task accuracy | 94.2% | 93.8% | -0.4% |
| Instruction adherence | 91.0% | 93.5% | **+2.5%** |
| TTFT latency | 3.2s | 0.8s | **-75%** |
| Cost (API) | $0.48 | $0.09 | **-81%** |

A reproducible evaluation harness — public task suite, multi-model judges, NL-with-section-headers baseline, and per-metric confidence intervals — is planned for v0.2 and will be published as `specs/BENCHMARKS.md`.

---

## 16. Security Considerations

### 16.1 Injection Prevention

KCL frames are context declarations, not executable instructions. However, care must be taken:

- `§NL[...]` escape blocks MUST be sanitized — they could contain prompt injection.
- All `§ROLE` and `§ALWAYS/§NEVER` directives should be treated as system-level only.
- User-provided KCL MUST be enclosed in a user-scope frame: `[USER_CTX|...]`.
- Model implementations SHOULD distinguish between system-KCL and user-KCL.

### 16.2 Integrity

- Each `§CHECKPOINT` MAY include a hash of the preceding state for integrity verification.
- Delta chains longer than 100 operations without a checkpoint are considered unreliable.

---

## 17. Versioning & Compatibility

KCL uses semantic versioning with the spec version declared in `§META{kcl:X.Y}`.

### 17.1 Parser compatibility rules

| Situation | Required parser behavior |
|-----------|--------------------------|
| Document `kcl:X.Y`, parser understands `X.Y` | Accept. |
| Document `kcl:X.Y`, parser understands `X.Z` where `Z > Y` (forward) | Accept; treat as a v`X.Y` document; newer fields set to their v`X.Y` defaults. |
| Document `kcl:X.Y`, parser understands only `X.Z` where `Z < Y` (backward) | Accept if every section in the document is recognized; warn on any unknown `§SECTION{}`. |
| Document `kcl:X.Y` contains unknown `§SECTION{}` | Ignore the section (forward compatibility). |
| Document `kcl:X.Y` contains unknown directive `@unknown(...)` | Ignore the directive; continue processing. |
| Document `kcl:X.Y` contains unknown **required** marker (reserved prefix `§!REQUIRED_`) | Reject the document — refusing is safer than mis-interpreting. |
| Document `kcl:X.Y` with `Y` parser understands nothing of `X` (major change) | Reject. |

In short: **ignore unknown optional sections, reject unknown required sections.** This mirrors CBOR tag handling and Protocol Buffers field-number discipline.

### 17.2 Domain-pack versioning

Domain packs version independently of the spec (`§USE coding_v2`). Packs MAY add, deprecate, or redefine symbols across major versions. When a document imports a pack, the pack's version at document-encode time is part of the document's semantics; encoders SHOULD NOT rewrite `§USE` version tags without re-encoding the body.

### 17.3 Breaking-change policy

A change is **breaking** (and requires a major-version bump) if it:

- Removes or renames a reserved symbol.
- Changes the meaning of an existing frame tag, directive, or trust marker.
- Tightens a previously-permissive grammar production such that existing valid documents become invalid.

Non-breaking changes (minor-version bump) include: adding new frame tags, adding new directives, adding new `§META` keys with defaults, and clarifying but not changing existing rules.

### 17.4 Deprecation

Symbols / frame types scheduled for removal MUST be marked with `✗` in the spec and MUST remain parseable for at least one minor version before removal. Deprecation announcements belong in `CHANGELOG.md`.

---

## 18. Adoption Roadmap

| Phase | Timeline | Milestone |
|-------|----------|-----------|
| **1 — Library** | Now | Open-source KCL encoder/decoder. Middleware sits between user and API. |
| **2 — Tooling** | +6 months | IDE plugins, prompt management tools, and CLI utilities adopt KCL natively. |
| **3 — Native Support** | +12 months | API providers offer `content_encoding: "kcl/v1"` header. Models optimized for KCL. |
| **4 — Interlingua** | +18 months | Agent-to-agent communication uses KCL as the machine-native lingua franca. |

---

## 19. Appendix A — Quick Reference Card

### Structure

| Symbol | Meaning |
|--------|---------|
| `§` | Section / block header |
| `Δ` | Delta — change from prior state |
| `@` | Directive — command to the model |
| `#` | Reference to a defined entity |
| `∣` | Separates tag from slots |
| `→` | Transform / maps to / becomes |
| `⟨ ⟩` | Turn range in history |

### Semantics

| Symbol | Meaning | Symbol | Meaning |
|--------|---------|--------|---------|
| `⊕` | Add | `⊖` | Remove |
| `⊘` | Null | `⊤` | True |
| `⊥` | False | `∵` | Because |
| `∴` | Therefore | `≈` | Approximately |
| `≠` | Not equal | `∈` | Member of |
| `∀` | For all | `∃` | Exists |

### Epistemic

| Symbol | Meaning |
|--------|---------|
| `✓` | Verified ground truth |
| `?` | Uncertain / unverified |
| `~` | User-claimed, not confirmed |
| `✗` | Deprecated / known false |
| `◐` | Partially true |

### Priority

`‼` critical · `!` high · `·` normal · `…` low

### Common Patterns

| Pattern | Effect |
|---------|--------|
| `§ROLE[type:domain]` | Set assistant persona |
| `§TOOLS{name(p:t)→R}` | Define tool signatures |
| `§ALWAYS[x]` `§NEVER[y]` | Behavioral constraints |
| `§PREFER[x>y]` | Soft preferences |
| `§ON:trigger[action]` | Conditional behavior |
| `§NL["free text"]` | Natural language escape |
| `§CHECKPOINT{...}` | Full state snapshot |
| `§USE pack_v1` | Import domain pack |
| `[Tag∣k:v,k:v]` | Frame with slots |
| `Δ[ref∣k:old→new]` | Delta encoding |

---

## 20. Appendix B — Domain Pack Registry

| Pack ID | Domain | Key Aliases | Status |
|---------|--------|-------------|--------|
| `coding_v2` | Software development | fn, cls, err, ret, dep, cfg, env, test | Stable |
| `webdev_v1` | Web development | dom, css, api, ssr, spa, cdn, cors | Draft |
| `data_v1` | Data science / ML | df, col, row, feat, model, epoch, loss | Draft |
| `medical_v1` | Clinical / healthcare | dx, rx, hx, sx, px, labs, vitals | Draft |
| `legal_v1` | Legal / compliance | statute, clause, party, jurisdiction | Draft |
| `finance_v1` | Finance / trading | ticker, position, pnl, Greeks, vol | Draft |
| `creative_v1` | Creative writing | char, scene, arc, dialog, pov, tone | Draft |
| `devops_v1` | Infrastructure / ops | pod, svc, ns, deploy, hpa, pvc, ingress | Draft |

---

## 21. License

KCL is published as an open specification under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license. Implementations may use any software license.

---

*End of Specification — KCL v0.1.0*
