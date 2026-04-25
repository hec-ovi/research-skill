# Changelog

All notable changes to this skill will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this skill adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-04-25

### Added

- Initial release of the `research` skill.
- Frontmatter conforming to [agentskills.io](https://agentskills.io/specification): `name`, `description`, `when_to_use`, `user-invocable`, `argument-hint`.
- Project-scoped data layout: `<project>/.claude/research/{INDEX.md, <topic-slug>/FINDINGS.md, <topic-slug>/raw/}`.
- Auto-create on first use, with `.gitignore` entry for privacy by default.
- Progressive disclosure loading hierarchy: 5 tiers from `INDEX.md` (always) down to raw documents (on demand).
- Subagent-isolated Investigation phase with mode-specific briefs (new entry vs merge).
- Cognitive phases: Decompose → Gather → Validate → Contrarian → Synthesize.
- Subagent returns structured text only; main agent owns all file writes.
- Conflict-handling history via `## Discarded approaches` table — supersession is explicit, never silent.
- Raw document support with extension preservation (`.md`, `.pdf`, `.txt`, `.html`, etc.).
- Cross-entry linking via `related:` frontmatter.
- Pasted-content workflow with optional original-file deletion offer (always asks, never auto-deletes).
- Best-practices section: date pinning, version preference (stable > nightly), source-authority hierarchy, citation discipline.
