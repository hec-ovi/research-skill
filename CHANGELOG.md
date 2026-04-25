# Changelog

All notable changes to this skill will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-04-25

### Fixed

- **SKILL.md**: removed reference to `claude-code-permission-prompts`, a research entry that exists only in the maintainer's local `.research/` store. The reference was carried over from personal context during development; for any other installer it pointed at nothing. The plain-text explanation of the sensitive-path guard remains.
- **SKILL.md**: removed the `(hook-enforced)` annotation next to `model: "opus"` in the Investigation step. The hook lives in the maintainer's `~/.claude/settings.json` and was carried over into skill text by mistake; for other installers the parenthetical was misleading. Replaced with a short note explaining why the Investigation phase needs a strong model.

### Changed

- **README**: install routes reordered. `npx skills add` (cross-tool, generic) is now route 1, Claude Code plugin marketplace is route 2, git clone is route 3.
- **README**: route 2 renamed from "Anthropic plugin marketplace" to "Claude Code plugin marketplace". The marketplace mechanism is Claude Code's; the marketplace itself is hosted on the maintainer's GitHub, not Anthropic's first-party catalog. Old wording risked implying official Anthropic distribution.
- **README**: new "Built for compaction and large-research recall" section added near the top, framing the skill's killer use case (research that survives `/compact` and recalls progressively via INDEX, then Summary, then full body).
- **CHANGELOG**: removed unqualified GitHub issue numbers from the 0.2.0 entry. They were ambiguous about which repo they referenced and added confusion without value.

## [0.2.0] - 2026-04-25

### Changed

- **Data location moved from `<project>/.claude/research/` to `<project>/.research/`.** Claude Code applies a hard-coded "sensitive directory" guard to `.claude/` paths that runs before user permission rules. Storing data outside `.claude/` eliminates per-write permission prompts entirely.
- **README**: full visual rewrite with centered title, status / compatibility / feature badges, structured horizontal-rule separators. Three install routes presented prominently.

### Removed

- Setup step 5 (auto-configure `~/.claude/settings.json` allow patterns). The pre-allow approach was based on a false premise; pre-allow patterns do not bypass the sensitive-path guard. With the data location moved to `.research/`, the step is no longer needed.

### Added

- **Plugin marketplace install route**: `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` enable `/plugin marketplace add hec-ovi/research-skill` then `/plugin install research@research-skill`. Repo now installs three ways.
- **Canonical plugin skills layout**: `skills/research/SKILL.md` symlink to root `SKILL.md` so the plugin install path coexists with the git-clone-friendly root layout. No file duplication.
- Influences and citations section in `README.md`: explicit credit and source links for Anthropic Agent Skills spec, xAI Grok multi-agent / DeepSearch pattern, and GBrain RESOLVER.md dispatcher pattern.
- Async-by-default Investigation: subagents are now spawned with `run_in_background: true` so the conversation stays interactive while research runs. Storage applies on completion notification.
- Naming convention for spawned subagents: `description: "Research investigation: <topic>"` for harness-UI identifiability.

## [0.1.0] - 2026-04-25

### Added

- Initial release of the `research` skill.
- Frontmatter conforming to [agentskills.io](https://agentskills.io/specification): `name`, `description`, `when_to_use`, `user-invocable`, `argument-hint`.
- Project-scoped data layout: `<project>/.claude/research/{INDEX.md, <topic-slug>/FINDINGS.md, <topic-slug>/raw/}`.
- Auto-create on first use, with `.gitignore` entry for privacy by default.
- Progressive disclosure loading hierarchy: 5 tiers from `INDEX.md` (always) down to raw documents (on demand).
- Subagent-isolated Investigation phase with mode-specific briefs (new entry vs merge).
- Cognitive phases: Decompose → Gather → Validate → Contrarian → Synthesize.
- Subagent returns structured text only; main agent owns all file writes.
- Conflict-handling history via `## Discarded approaches` table - supersession is explicit, never silent.
- Raw document support with extension preservation (`.md`, `.pdf`, `.txt`, `.html`, etc.).
- Cross-entry linking via `related:` frontmatter.
- Pasted-content workflow with optional original-file deletion offer (always asks, never auto-deletes).
- Best-practices section: date pinning, version preference (stable > nightly), source-authority hierarchy, citation discipline.
