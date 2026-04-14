# Changelog

All notable changes to khala (both the KCL spec and the Claude Code plugin) are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the spec component uses semantic versioning as defined in `specs/KCL-SPEC-v0.1.md` §17.

## [Unreleased]

### Added

- Bootstrap integrity: SHA-256 digests pinned in `specs/SHA256SUMS` and verified by the SessionStart hook.
- `[USER_CTX|...]` scope-wrapping nudge injected when Read/Edit/Write targets a `.kcl` outside the plugin root.
- `specs/BENCHMARKS.md` placeholder documenting the v0.2 evaluation harness plan.
- KCL-SPEC §17 "Versioning & Compatibility" with forward/backward compatibility rules.
- Operational definitions for epistemic markers (`✓ ? ~ ✗ ◐`) and `§PREFER` ordering.
- ASCII fallback guidance for rare symbols (`‼ ◐ · ⟨ ⟩`) that tokenize unpredictably.

### Changed

- Benchmark tables in README and KCL-SPEC §15 relabelled as **illustrative design targets**, not measurements.
- `§ON:trigger[...]` rewritten to grammar-legal `§ON[trigger:..., action:..., then:...]`.
- ASCII `|` (U+007C) is now normative; `∣` (U+2223) is display-only — not interchangeable.
- `compress_level` enum converged to `conservative / standard / aggressive` (removed undefined `moderate`).
- Delta REF syntax: `Δ[#id|...]` with an explicit frame-ID resolution rule (`id:` slot → TAG fallback → error).
- VALUE tokenization rule: bare tokens may not contain `: , ] } | → "` or whitespace; otherwise quote.
- Tool-def "lossless" claim qualified — complex JSON-Schema constraints require `§TOOLS` extensions or `§NL[]`.

### Removed

- Unsupported "3.2× higher attention weight" constant from P1 (reframed as open empirical question).
- Unused `[TAG:VALUE]` FRAME shorthand that collided with `LIST`.

### Security

- PATH_ARG sanitized (control chars stripped, 256-char cap) before injection into hook `additionalContext` — prevents second-order prompt injection via crafted filenames.
- Prompt length capped at 16 KiB before hook regex execution — prevents 5 s timeout DOS.
- URL spans stripped from `.kcl` filename regex — prevents phishing-style nudges on `https://.../foo.kcl`.

## [0.1.0] — 2026-04-14

### Added

- Initial KCL v0.1 specification (`specs/KCL-SPEC-v0.1.md`).
- Two-stage self-teaching bootstrap (`specs/KCL-BOOTSTRAP-v0.1.md`).
- Claude Code plugin with three skills: `kcl-read`, `kcl-write`, `kcl-translate`.
- Enforcement hooks: `SessionStart`, `UserPromptSubmit`, `PreToolUse (Read|Write|Edit)`.
- Marketplace manifest (`.claude-plugin/marketplace.json`) for single-plugin install.
- Apache-2.0 for plugin code; CC-BY-4.0 for the language specification.
