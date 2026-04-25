<h1 align="center">research-skill</h1>

<p align="center">
  <strong>Persistent project-scoped store for deep research findings, with progressive disclosure and contrarian-pass investigation.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Live-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/Version-0.2.2-blue" alt="Version" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Spec-agentskills.io-7B3FA0" alt="Spec" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-Native-D97757?logo=anthropic&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/SKILL.md_format-Compatible-7B3FA0" alt="SKILL.md compatible" />
  <img src="https://img.shields.io/badge/Code_CLIs-Cross--tool-2496ED" alt="Cross-tool" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Investigation-Async_Opus_4.7-9A48A6" alt="Async investigation" />
  <img src="https://img.shields.io/badge/Disclosure-Progressive-FF6B6B" alt="Progressive disclosure" />
  <img src="https://img.shields.io/badge/Inspired_by-Grok_+_GBrain-E63946" alt="Inspirations" />
  <img src="https://img.shields.io/badge/Install-3_routes-2496ED" alt="Install routes" />
</p>

---

## What this is

A Claude Code skill that gives you a persistent, project-scoped store for deep research findings.

Stop re-researching the same topics across sessions. Stop polluting conversation context with raw web search dumps. The skill maintains a structured local knowledge base under `<project>/.research/`, looks it up before fetching the web, and uses progressive disclosure to load only what's actually needed.

---

## Built for compaction and large-research recall

Long Claude Code sessions run out of context. `/compact` summarizes older turns and drops the rest, so findings from a deep research thread evaporate and the next question re-triggers the same web searches.

This skill makes the data layer outlive the chat. Research written today survives `/compact`, `/clear`, IDE restarts, and machine moves. The next session reads `INDEX.md` first (a tiny dispatcher), matches the topic, and pulls only the matched entry's `## Summary` section into context. The full body stays on disk until you actually need it.

Loading tiers, cheapest first:

| Tier | Loads | Approx tokens | When |
|---|---|---|---|
| 1 | `INDEX.md` | 100 to 500 | Every retrieval |
| 2 | Entry's `## Summary` only | 50 to 200 | When INDEX shows a match |
| 3 | Full `FINDINGS.md` body | 500 to 3000 | When the summary doesn't cover it |

Heavy research artifacts become cheap to recall: you only pay for the tier you need.

---

## What's distinctive

- **Project-scoped, not global.** Each repo has its own research store, kept private (gitignored by default).
- **Progressive disclosure.** Index, then summary, then full body, in that order. Most lookups never load the full entry.
- **Conflict-handling history.** When findings change, old claims move to a `## Discarded approaches` table with reasons; never silently overwritten. Prevents re-trying refuted approaches.
- **Subagent-isolated investigation.** Heavy WebSearch / WebFetch traffic runs in a separate `general-purpose` subagent (Opus 4.7 by default). Your main context stays clean.
- **Async, non-blocking.** The investigation subagent runs in background mode (`run_in_background: true`); your conversation with Claude Code stays interactive while research happens. Findings save and announce themselves on the completion notification. No frozen CLI.
- **Cognitive phases.** Decompose, Gather, Validate, **Contrarian pass**, Synthesize. The contrarian pass actively searches for "why this is wrong" rather than confirming. It earns its keep.

---

## How findings reach your conversation

When the Investigation subagent finishes, its full structured return (Summary, Findings, contrarian objection, sources) is injected into the main agent's context as a task-notification message. No file round-trip, no tail-the-log polling. The main agent parses the return directly and writes the data layer.

Why this matters:

- **No raw web-search dump pollution.** The main agent only sees the agent's clean synthesized output, never the raw web search results or fetch responses. Those live in a separate transcript file the main agent is forbidden to read.
- **Storage is deterministic.** The required output format maps 1:1 to the FINDINGS.md schema. Parsing is mechanical, not interpretive.
- **Conversation stays interactive.** The subagent runs in background mode (`run_in_background: true`), so you keep working while it researches; the structured output arrives as a notification when the agent completes.

---

## Install

Three install routes, all global. No registration, approval, or login required.

### 1. `npx skills add` (cross-tool, any code CLI that implements the open SKILL.md format)

```bash
npx skills add hec-ovi/research-skill
```

### 2. Claude Code plugin marketplace

```
/plugin marketplace add hec-ovi/research-skill
/plugin install research@research-skill
```

This uses Claude Code's built-in marketplace mechanism to install the plugin from the maintainer's GitHub repo. It is not Anthropic's first-party catalog.

### 3. Direct git clone (simplest, works anywhere)

```bash
# Personal (across all your projects)
git clone https://github.com/hec-ovi/research-skill ~/.claude/skills/research

# Or project-only
git clone https://github.com/hec-ovi/research-skill <your-project>/.claude/skills/research
```

Claude Code picks up new skills live, no restart needed.

---

## Usage

The skill auto-activates when you ask a research-style question. You can also invoke it explicitly:

```
/research <topic>
```

Examples:

- *"What's the latest TypeScript ORM for edge runtime in 2026?"*
- *"Compare Bun vs Node cold-starts for serverless"*
- *"/research drizzle-type-generation"*

---

## Data layout

The skill writes to your project, not your home dir:

```
<project>/.research/
├── INDEX.md                  # dispatcher: topic table, scanned first
└── <topic-slug>/
    ├── FINDINGS.md           # entry: frontmatter + summary + findings + history
    └── raw/                  # optional: pasted PDFs, whitepapers, etc.
```

`INDEX.md` is the dispatcher, equivalent to `RESOLVER.md` in the GBrain pattern. The agent reads it first, then loads only the matched entry's `## Summary` section. Full entries and raw documents only load on demand.

`.research/` is deliberately outside `<project>/.claude/` to dodge Claude Code's hard-coded sensitive-path guard, which prompts on every read or write to anything under `.claude/` regardless of `permissions.allow` settings.

---

## When NOT to use

- Plan-stage notes
- Small facts or one-line preferences
- Code-level decisions tied to one file
- Casual lookups answerable from a single source
- A substitute for a single WebSearch / WebFetch

If the question fits in one search plus 1 to 2 sentences, you don't need this skill.

---

## Influences and citations

Built explicitly on three open patterns; credit where due.

### Agent Skills specification

Frontmatter and folder layout follow the open [Agent Skills specification](https://agentskills.io/specification) (Apache 2.0 / CC-BY-4.0). Portable across Claude Code and any other code CLI that implements the SKILL.md format.

### Grok deep-research multi-agent pattern (xAI)

The Investigation phase walks a 5-step cognitive workflow (Decompose, Gather, Validate, Contrarian pass, Synthesize) adapted from xAI's published [Multi-Agent architecture](https://docs.x.ai/developers/model-capabilities/text/multi-agent) and the [DeepSearch announcement](https://x.ai/news/grok-3). xAI ships 4 specialized agents (Captain, Harper, Benjamin, Lucas) on a shared backbone; this skill condenses those into cognitive phases a single subagent walks, since the Claude Code harness does not currently expose subagent continuation (`SendMessage` unavailable as of April 2026).

The Contrarian pass (phase 4) is the standout borrowed element: actively searching for "why this is wrong" rather than confirming. In an A/B test on a celebrity-fronted AI tool legitimacy question, the contrarian pass surfaced significant controversy that a minimal-brief baseline missed.

### GBrain RESOLVER pattern (Garry Tan)

`INDEX.md` acts as a dispatcher in the same role as [`RESOLVER.md`](https://github.com/garrytan/gbrain/blob/master/skills/RESOLVER.md) in [GBrain](https://github.com/garrytan/gbrain). The INDEX is scanned first; full entries load only on match. Progressive disclosure tiers borrow GBrain's "thin harness, fat skills" philosophy ([`THIN_HARNESS_FAT_SKILLS.md`](https://github.com/garrytan/gbrain/blob/master/docs/ethos/THIN_HARNESS_FAT_SKILLS.md)).

---

## Schema

Every entry's `FINDINGS.md` has structured frontmatter (`topic`, `created`, `last_verified`, `status`, `related`, `sources`, `raw`) and a body with `## Summary`, `## Findings`, `## Discarded approaches`, `## Open questions`, `## Timeline`. See [`SKILL.md`](SKILL.md) for the full schema and rules.

---

## Requirements

- A code CLI that implements the [SKILL.md format](https://agentskills.io/specification) (Claude Code, or any other compatible client)
- For the Investigation phase: an Opus-class model accessible to the spawning agent (the skill defaults to spawning subagents at `model: "opus"`)

---

## Recommended setup

### Pin subagents to Opus

The Investigation phase needs reasoning depth. The skill spawns subagents with `model: "opus"`, but the calling agent has to actually pass that parameter on every spawn. To make it systematic across all your Claude Code sessions, configure your environment to default subagents to Opus.

Two practical approaches:

- **Hook (strongest)**: add a `PreToolUse` hook on the `Agent` tool in `~/.claude/settings.json` that blocks any spawn whose `model` field is not `opus`. The hook runs before the tool dispatches, so a non-opus spawn never reaches the API.
- **Convention (lightest)**: add a one-line note to your `~/.claude/CLAUDE.md`: *"Every Agent tool call MUST pass `model: \"opus\"`."* Claude reads CLAUDE.md every session.

Smaller models work fine for the main conversation. The contrarian pass and synthesis steps in Investigation specifically depend on Opus-class reasoning depth; smaller models tend to skip the contrarian phase or produce shallow syntheses.

---

## License

[MIT](LICENSE). Free to use, modify, fork, distribute. Attribution appreciated, not required.
