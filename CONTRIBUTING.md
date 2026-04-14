# Contributing to khala

Thank you for considering a contribution. khala is a dual artifact — a language specification and a Claude Code plugin — and contributions can target either layer.

## Scope

| Layer | Files | License | Review focus |
|-------|-------|---------|--------------|
| Specification | `specs/*.md` | CC-BY-4.0 | Grammar precision, cross-model parseability, backward compatibility |
| Plugin | `.claude-plugin/`, `skills/`, `hooks/`, `scripts/` | Apache-2.0 | Security, skill-discovery UX, hook safety |

Mixing changes across layers in a single PR is discouraged — please split into one PR per layer.

## Before you open a PR

1. **Read the relevant spec section.** Spec changes must cite a specific §N.M being modified and explain why.
2. **Re-compute SHA-256 digests** if you change either spec file: `sha256sum specs/KCL-BOOTSTRAP-v0.1.md specs/KCL-SPEC-v0.1.md > specs/SHA256SUMS`.
3. **Keep the bootstrap and normative spec in sync.** Any semantic change to `KCL-SPEC-v0.1.md` must be reflected in `KCL-BOOTSTRAP-v0.1.md` (Stage 1 symbols and/or Stage 2 KCL body).
4. **Assign an issue code.** New findings use the convention `B# / H# / M# / L#` (Blocker / High / Medium / Low). Continue numbering from the highest existing code in `CHANGELOG.md`. Reference the code in your commit subject, e.g. `Fix ... (H12)`.
5. **Preserve backward compatibility** unless the change explicitly bumps the major spec version per §17. Removing or redefining a reserved symbol, frame tag, or directive requires a major bump and a deprecation entry in `CHANGELOG.md`.

## Commit & PR conventions

- **Commit subject:** imperative, ≤72 chars, ends with the issue code in parentheses when one applies. Example: `Relabel prototype benchmarks as illustrative v0.1 design targets (H4)`.
- **One issue per commit.** Bundle only when changes are tightly coupled (e.g. grammar change + SHA256SUMS refresh).
- **PR description:** list the codes resolved and link to the spec sections touched.

## Spec changes that require an RFC

For anything listed below, open a discussion issue before writing code:

- Adding a new reserved symbol or frame tag.
- Changing the semantics of an existing symbol or marker.
- Introducing a new tier.
- Changing the bootstrap preamble format.
- Any change that would require an existing well-formed KCL document to re-encode.

## Plugin changes

- Hook scripts must be shell-safe on both `bash` and `zsh` with `set -euo pipefail` and no unquoted expansions of user-controlled data.
- Smoke-test each hook before committing:
  ```bash
  echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x.kcl"}}' | \
    CLAUDE_PLUGIN_ROOT=$(pwd) ./scripts/enforce-kcl-skills.sh
  ```
- `SKILL.md` frontmatter must include `name:` and a description front-loaded with user-phrase triggers.

## Benchmarks

Do not introduce new performance numbers into `README.md` or `KCL-SPEC-v0.1.md` without first updating `specs/BENCHMARKS.md` with methodology, sample size, confidence intervals, and a runnable harness. Every citable number requires a reproducible result behind it.

## Contact

Chiro — `chiro@orochi.network` · [Orochi Network](https://orochi.network)
