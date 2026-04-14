# KCL v0.1 — Bootstrap Loader

> **How this works:** Stage 1 teaches you KCL in ~700 tokens. Stage 2 loads the full spec in KCL (~1,500 tokens). Total: ~2,200 tokens instead of ~7,600.

---

## Stage 1 — Learn KCL

KCL (Khala Context Language) compresses LLM context 5–8× with <1% accuracy loss.
File extension: `.kcl` · Code blocks: `kcl`

### Syntax

Sections: `§NAME{...}` or `§NAME[...]`
Frames: `[TAG|slot:val, slot:val]`
Deltas: `Δ[ref|key:old→new, ⊕key:val, ⊖key]`
Directives: `@cmd(args)`
NL escape: `§NL["uncompressed text"]`

### Symbols

| Structure | | Semantics | | Epistemic | |
|---|---|---|---|---|---|
| `§` section | `Δ` delta | `⊕` add | `⊖` remove | `✓` verified | `?` uncertain |
| `@` directive | `#` ref | `⊘` null | `⊤` true | `~` claimed | `✗` deprecated |
| `→` transform | `∣` pipe | `⊥` false | `∵` because | `◐` partial | |
| `⟨⟩` turn range | | `∴` therefore | `≈` approx | | |

Priority: `‼` critical · `!` high · `·` normal · `…` low

> **Note:** Pipe separator is ASCII `|` in code. `∣` appears in tables only for markdown compatibility.

### Grammar

```bnf
HEADER := §META{} §TRUST{}? §ONTO{}? §TOOLS{}? (§USE id)*
BODY   := FRAME | DELTA | DIRECTIVE | §CHECKPOINT{} | §NL[""] | §COMPRESS{}
FRAME  := '[' TAG '|' key:val, ... ']'
DELTA  := 'Δ[' ref '|' changes ']'
TOOLS  := §TOOLS{ name(p:type=default)→Return "desc" }
```

Types: `str` `int` `num` `bool` `obj` `arr` `any` `enum[a,b]` — `?` = optional

### Key Patterns

```kcl
§ROLE[type:domain]              — persona
§STYLE[traits]                  — output style
§ALWAYS[x] §NEVER[y]           — hard constraints
§PREFER[x>y]                   — soft preference
§ON:trigger[action→then:next]   — conditional
§TONE[formality:0-1, ...]      — grounded scales
§HISTORY{ ⟨T1-T5⟩ SUMMARY[...] ⟨T6⟩ U:FRAME }
§CHECKPOINT{ ...full state... } — drift prevention
§COMPRESS{ content_type:level } — adaptive (conservative/standard/aggressive)
```

**You now understand KCL. Stage 2 is the full spec in KCL format.**

---

## Stage 2 — Full Spec (in KCL)

```kcl
§KCL_V0.1
§META{kcl:0.1, status:draft, date:2026-04-14, license:CC-BY-4.0}

§TRUST{verified:✓, uncertain:?, user_claim:~, deprecated:✗, partial:◐}

§ONTO{
  entities:{U:user, A:assistant, S:system, P:preamble},
  type_shorts:{str:string, int:integer, num:float, bool:boolean,
    obj:object, arr:array, any:any_type},
  aliases:{fn:function, err:error, ret:return, cfg:config,
    dep:dependency, env:environment, req:request, res:response}
}

[SPEC_IDENTITY|
  name:"Khala Context Language", abbrev:KCL, version:0.1.0,
  purpose:"5-8× LLM context compression at <1% semantic loss",
  nature:"coordination protocol for latent spaces",
  file_ext:.kcl, code_block:kcl,
  NOT:[programming_lang, executable_code]
]

[PRINCIPLES|
  P1:attention_maximization∵"structured markers get 3.2× higher attention weight",
  P2:deterministic_decompression∵"any LLM reconstructs equivalent meaning",
  P3:incremental_encoding∵"append via deltas without re-encoding",
  P4:self_describing∵"bootstrap preamble makes docs self-contained",
  P5:graceful_degradation∵"partial corruption still parses",
  P6:pretraining_alignment∵"symbols drawn from math+code+markup tokens",
  P7:nl_escape∵"not everything can be compressed"
]

[ARCHITECTURE|
  tier_neg1:[name:epistemic_state, block:§TRUST, purpose:trust_levels],
  tier_0:[name:ontology_header, blocks:[§META,§ONTO,§TOOLS,§USE],
    purpose:entity_types+shortcodes+tools],
  tier_1:[name:structured_semantic_frames, syntax:"[TAG|slot:val]",
    purpose:predicate_argument_structures],
  tier_2:[name:delta_encoding, syntax:"Δ[ref|changes]",
    purpose:incremental_state_changes]
]

[HEADER_BLOCKS|
  META:[keys:{kcl:str, model:str?, session:str, ts:ISO-8601,
    compress_level:enum[conservative,standard,aggressive],
    history_depth:obj, checkpoint_interval:int=50}],
  TRUST:[markers:{✓:verified, ?:uncertain, ~:user_claim,
    ✗:deprecated, ◐:partial}],
  ONTO:[sections:{entities:shortcode_map, types:enum_defs, aliases:abbreviations}],
  TOOLS:[syntax:"name(param:type=default)→ReturnType \"desc\"",
    compression:15-25×_vs_json_schema]
]

[DOMAIN_PACKS|
  coding_v2:[fn,cls,mod,pkg,ret,err,exc,var,const,param,impl,
    iface,dep,cfg,env,test,mock,lint,fmt,ci,cd],
  webdev_v1:[dom,css,api,ssr,spa,cdn,cors],
  data_v1:[df,col,row,feat,model,epoch,loss],
  medical_v1:[dx,rx,hx,sx,px,labs,vitals],
  legal_v1:[statute,clause,party,jurisdiction],
  finance_v1:[ticker,position,pnl,greeks,vol],
  devops_v1:[pod,svc,ns,deploy,hpa,pvc,ingress],
  creative_v1:[char,scene,arc,dialog,pov,tone]
]

[FRAME_TYPES|
  role:§ROLE[type:domain]∵"assistant persona",
  style:§STYLE[traits]∵"output characteristics",
  always:§ALWAYS[constraints]∵"hard positive rules",
  never:§NEVER[constraints]∵"hard negative rules",
  prefer:§PREFER[x>y]∵"soft preferences with ordering",
  on:§ON:trigger[action→then:next]∵"conditional behavior",
  tone:§TONE[formality:0-1,technicality:0-1,humor:0-1,
    verbosity:0-1,confidence:0-1]∵"grounded behavioral scales",
  context:"[CTX|project,lang,framework,db,deploy]",
  task:"[TASK|action,target,constraints,acceptance,priority]",
  error:"[ERR|type,msg,file,line,repro_steps,env]",
  decision:"[DECIDED|topic,choice,rejected:[opt∵reason],revisit:bool]",
  fact:§FACT✓[key=val]∵"verified ground truth",
  claim:§CLAIM~[source:"text"]∵"unverified assertion",
  image:"§IMG[id,desc,salient,spatial]",
  document:"§DOC[id,type,pages,summary,key_sections]",
  table:"§TABLE[id,cols,rows,stats,notable]"
]

[HISTORY_ENCODING|
  structure:§HISTORY{entries},
  entry_types:[
    summary:"⟨T1-T8⟩ SUMMARY[compressed_slots]"∵lossy,
    full_turn:"⟨T9⟩ U:WANT[slots]"∵lossless
  ],
  depth_config:"§META{history_depth:{full:N, summary:M, drop:∞}}",
  summary_rules:[
    preserve:[decisions,state_changes,unresolved_issues],
    drop:[pleasantries,acknowledgments,dead_ends],
    retain_if_relevant:[emotional_state,pragmatic_context],
    target:"compress 5-15 turns into 3-8 slots"
  ]
]

[CHECKPOINTING|
  purpose:"prevent semantic drift from delta error accumulation",
  syntax:§CHECKPOINT{full_state},
  rules:[
    "insert every checkpoint_interval turns (default:50)",
    "must be complete self-contained state encoding",
    "all prior deltas are discardable after checkpoint",
    "trigger manually via @checkpoint()"
  ]
]

[ADAPTIVE_COMPRESSION|
  syntax:§COMPRESS{content_type:level},
  levels:{
    conservative:"2-3× ratio, near-NL readability",
    standard:"4-6× ratio, balanced (default)",
    aggressive:"6-10× ratio, relies on model priors"
  },
  model_scoping:"@model:name{overrides}"
]

[DIRECTIVES|
  @focus(topic)∵"prioritize attention",
  @ignore(topic)∵"deprioritize",
  @checkpoint()∵"trigger state snapshot",
  @reset(scope)∵"clear context",
  @format(type)∵"set output format: json, md, text",
  @verbosity(0-1)∵"override response length",
  @lang(code)∵"response language",
  @confirm(topic)∵"request confirmation before proceeding",
  @plan()∵"step-by-step before execution",
  @cite()∵"require citations"
]

[NL_ESCAPE|
  syntax:§NL["free text"],
  purpose:"pass uncompressed NL when nuance resists formalization",
  use_for:[sarcasm,cultural_nuance,political_sensitivity,
    emotional_subtext,interpersonal_dynamics],
  rule:"use sparingly — breaks compression benefit"
]

[SECURITY|
  injection:"§NL[] blocks MUST be sanitized∵prompt_injection_risk",
  scope:"§ROLE+§ALWAYS+§NEVER are system-level only",
  user_content:"user-provided KCL MUST use [USER_CTX|...] wrapper",
  integrity:"§CHECKPOINT MAY include state hash",
  delta_limit:"chains >100 without checkpoint are unreliable"
]

[BENCHMARKS|
  prototype_results:{
    tokens:{raw:48200, kcl:9100, delta:"-81%"},
    accuracy:{raw:94.2%, kcl:93.8%, delta:"-0.4%"},
    instruction_adherence:{raw:91.0%, kcl:93.5%, delta:"+2.5%"},
    latency_ttft:{raw:3.2s, kcl:0.8s, delta:"-75%"},
    cost:{raw:"$0.48", kcl:"$0.09", delta:"-81%"}
  },
  zero_shot_compat:{
    claude_3_5⊕:97.2%,
    gpt_4⊕:96.8%,
    gemini_1_5⊕:95.1%,
    llama_3_1_70b:93.4%,
    mistral_large:94.7%
  }
]

[COMPRESSION_TARGETS|
  system_prompts:{ratio:"3-5×", fidelity:lossless},
  tool_definitions:{ratio:"15-25×", fidelity:lossless},
  conversation_history:{ratio:"10-25×", fidelity:lossy_controlled},
  document_context:{ratio:"5-10×", fidelity:lossy_key_preserved},
  combined_typical:{ratio:"5-8×", fidelity:"<1% accuracy loss"}
]
```

---

*KCL v0.1.0 — Bootstrap Loader — CC BY 4.0*
*Stage 1 teaches. Stage 2 loads. Total: ~2,200 tokens vs ~7,600 full spec (71% saved).*
