# research

A Claude Code skill that gives you a persistent, project-scoped store for deep research findings.

Stop re-researching the same topics across sessions. Stop polluting conversation context with raw web search dumps. The skill maintains a structured local knowledge base under `.claude/research/`, looks it up before fetching the web, and uses progressive disclosure to load only what's needed.

## What's distinctive

- **Project-scoped, not global.** Each repo has its own research store, kept private (gitignored by default).
- **Progressive disclosure.** Index → summary → full body, in that order. Most lookups never load the full entry.
- **Conflict-handling history.** When findings change, old claims move to `## Discarded approaches` with reasons - never silently overwritten. Prevents re-trying refuted approaches.
- **Subagent-isolated investigation.** Heavy WebSearch / WebFetch work happens in a separate agent (Opus 4.7 by default). Your main context stays clean.
- **Cognitive phases.** Decompose → Gather → Validate → Contrarian → Synthesize. The contrarian pass actively searches for "why this is wrong" - not just confirmation bias.

## Influences and citations

This skill draws on three open patterns. Credit where due.

### Agent Skills specification (Anthropic)

Frontmatter and folder layout follow the open [Agent Skills specification](https://agentskills.io/specification) (Apache 2.0 / CC-BY-4.0). The skill is portable across Claude Code, OpenAI Codex, Cursor, Gemini CLI, and other adopters of the spec.

### Grok's deep-research multi-agent pattern (xAI)

The Investigation phase walks a 5-step cognitive workflow (Decompose, Gather, Validate, Contrarian pass, Synthesize) adapted from xAI's published [Multi-Agent architecture](https://docs.x.ai/developers/model-capabilities/text/multi-agent) and the [DeepSearch announcement](https://x.ai/news/grok-3). xAI's implementation uses 4 specialized agents (Captain, Harper, Benjamin, Lucas) on a shared backbone; this skill condenses those into cognitive phases a single subagent walks, since the Claude Code harness does not currently expose subagent continuation (the `SendMessage` tool is unavailable as of April 2026).

The Contrarian pass (phase 4) is the standout borrowed element: actively searching for "why this is wrong" rather than just confirming. In an A/B test on a celebrity-fronted AI tool legitimacy question, the contrarian pass surfaced significant controversy that a minimal-brief baseline missed.

### GBrain's RESOLVER pattern (Garry Tan)

`INDEX.md` acts as a dispatcher in the same role as [`RESOLVER.md`](https://github.com/garrytan/gbrain/blob/master/skills/RESOLVER.md) in [GBrain](https://github.com/garrytan/gbrain). The INDEX is scanned first; full entries load only on match. Progressive disclosure tiers borrow GBrain's "thin harness, fat skills" philosophy ([`THIN_HARNESS_FAT_SKILLS.md`](https://github.com/garrytan/gbrain/blob/master/docs/ethos/THIN_HARNESS_FAT_SKILLS.md)).

## Install

```bash
# Personal (across all your projects)
git clone https://github.com/<user>/research-skill ~/.claude/skills/research

# Or project-only
git clone https://github.com/<user>/research-skill <your-project>/.claude/skills/research
```

Claude Code picks up new skills live - no restart needed.

## Usage

The skill auto-activates when you ask a research-style question. You can also invoke it explicitly:

```
/research <topic>
```

Examples:

- *"What's the latest TypeScript ORM for edge runtime in 2026?"*
- *"Compare Bun vs Node cold-starts for serverless"*
- *"/research drizzle-type-generation"*

## Data layout

The skill writes to your project (not your home dir):

```
<project>/.claude/research/
├── INDEX.md                  # dispatcher - topic table, scanned first
└── <topic-slug>/
    ├── FINDINGS.md           # entry: frontmatter + summary + findings + history
    └── raw/                  # optional: pasted PDFs, whitepapers, etc.
```

`INDEX.md` is the dispatcher - equivalent to `RESOLVER.md` in the GBrain pattern. The agent reads it first, then loads only the matched entry's `## Summary` section. Full entries and raw documents only load on demand.

## When NOT to use

- Plan-stage notes
- Small facts or one-line preferences
- Code-level decisions tied to one file
- Casual lookups answerable from a single source
- A substitute for a single WebSearch / WebFetch

If the question fits in one search + 1-2 sentences, you don't need this skill.

## Schema

Every entry's `FINDINGS.md` has structured frontmatter (`topic`, `created`, `last_verified`, `status`, `related`, `sources`, `raw`) and a body with `## Summary`, `## Findings`, `## Discarded approaches`, `## Open questions`, `## Timeline`. See `SKILL.md` for the full schema and rules.

## Requirements

- [Claude Code](https://claude.com/code) - CLI, desktop app, or IDE extension
- Opus model access (the skill defaults to spawning investigation subagents at `model: "opus"`)

## License

MIT - see `LICENSE`.
