# KCL Benchmarks — Methodology & Status

**Status:** Not yet measured. This document is a placeholder for the v0.2 evaluation harness.

---

## Why this file exists

KCL v0.1 ships with an illustrative benchmark table in `README.md` and `specs/KCL-SPEC-v0.1.md` §15. Those numbers are **design targets**, not measurements:

- No public task suite has been run.
- No sample sizes, confidence intervals, or significance tests have been computed.
- No prose-with-section-headers baseline exists (required to isolate the KCL-specific signal from a general prompt-engineering confound).
- The token-count and cost deltas are tautologically linked.

Citing the v0.1 tables as measured results is incorrect. If you need KCL performance numbers for a decision, reach out to <chiro@orochi.network> or wait for v0.2.

---

## Planned v0.2 harness

The v0.2 evaluation will publish, in this file:

1. **Task suite.** A held-out mix drawn from IFEval (instruction following), BBH (reasoning), MT-Bench-style multi-turn, and a ToolBench subset re-encoded as KCL.
2. **Baselines.** Three conditions per task:
   - **NL-prose**: the original natural-language prompt.
   - **NL-structured**: the same prompt with section headers, bullets, and role tags — isolating the "structure helps" effect from the "KCL specifically helps" effect.
   - **KCL**: the KCL-encoded prompt at `compress_level:standard`.
3. **Model panel.** At minimum the v0.1 design panel (Gemma 4, Qwen 3.5, Claude Opus 4.6, Nemotron 3) plus two additional model families for cross-architecture coverage. Base (non-instruct) models included where weights are available.
4. **Metrics.**
   - Token counts (input + output, cache-adjusted).
   - Task accuracy, graded by independent LLM judges with published inter-rater agreement (κ) and a human-audited sample.
   - Instruction adherence via IFEval-style constraint-satisfaction scoring.
   - TTFT / end-to-end latency with ≥ 100 cold trials per condition.
   - Round-trip fidelity for md → kcl → md on a corpus of system prompts and tool definitions.
5. **Reporting.** Per-condition means with 95% bootstrap CIs; paired significance tests; ablations over `compress_level` and domain packs.
6. **Reproducibility.** Harness source, prompts, judge rubrics, and raw scores committed to `benchmarks/v0.2/` under Apache-2.0.

---

## Contributing

If you have an evaluation harness (or want to build one) that could be adopted here, open a PR. We prefer adopting an existing, well-cited suite (IFEval, BBH, HELM) over inventing a KCL-specific one, so the numbers are comparable to published baselines.

---

*Until v0.2 ships, treat every performance figure in the KCL documentation as a design target, not a measurement.*
