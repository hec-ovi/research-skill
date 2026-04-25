# Changelog

All notable changes to this skill will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Data location moved from `<project>/.claude/research/` to `<project>/.research/`.** Claude Code applies a hard-coded "sensitive directory" guard to `.claude/` paths that runs before user permission rules and cannot be bypassed by settings.json allow patterns or `--dangerously-skip-permissions` (confirmed via Anthropic docs and open issues #37029, #37253, #43001, #43406). Storing data outside `.claude/` eliminates per-write permission prompts entirely.
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
