<h1 align="center">research-skill</h1>

<p align="center">
  <strong>Persistent project-scoped store for deep research findings, with progressive disclosure and contrarian-pass investigation.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Live-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/Version-0.2.7-blue" alt="Version" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Spec-agentskills.io-7B3FA0" alt="Spec" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-Native-D97757?logo=anthropic&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Codex-Plugin_Native-2496ED" alt="Codex plugin native" />
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

A Claude Code and Codex skill that gives you a persistent, project-scoped store for deep research findings.

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
- **Subagent-isolated investigation.** Heavy web research can run in a separate subagent: Opus 4.7 in Claude Code, or GPT-5.5 xhigh in Codex when subagents are explicitly authorized. Your main context stays clean.
- **Async where supported.** In Claude Code, the investigation subagent runs in background mode (`run_in_background: true`) so the conversation stays interactive while research happens. In Codex, the plugin investigates inline unless the user explicitly authorizes subagents.
- **Cognitive phases.** Decompose, Gather, Validate, **Contrarian pass**, Synthesize. The contrarian pass actively searches for "why this is wrong" rather than confirming. It earns its keep.

---

## How findings reach your conversation

When a Claude Code Investigation subagent finishes, its full structured return (Summary, Findings, contrarian objection, sources) is injected into the main agent's context as a task-notification message. No file round-trip, no tail-the-log polling. The main agent parses the return directly and writes the data layer. In Codex, the same structured shape is used, either from an explicitly authorized subagent or from inline investigation.

Why this matters:

- **No raw web-search dump pollution.** The main agent only sees the agent's clean synthesized output, never the raw web search results or fetch responses. Those live in a separate transcript file the main agent is forbidden to read.
- **Storage is deterministic.** The required output format maps 1:1 to the FINDINGS.md schema. Parsing is mechanical, not interpretive.
- **Conversation stays interactive.** Claude Code uses background mode (`run_in_background: true`) for subagent investigation. Codex defaults to inline investigation unless the user explicitly asks for subagents.

---

## Install

Four install routes, all global. No registration, approval, or login required.

### 1. `npx skills add` (cross-tool, any code CLI that implements the open SKILL.md format)

```bash
npx skills add hec-ovi/research-skill
```

### 2. Claude Code plugin marketplace

```
/plugin marketplace add hec-ovi/research-skill
/plugin install research@research-skill
/reload-plugins
```

This uses Claude Code's built-in marketplace mechanism to install the plugin from the maintainer's GitHub repo. It is not Anthropic's first-party catalog.

### 3. Codex install guide

```bash
codex plugin marketplace add hec-ovi/research-skill
```

This uses the Codex plugin metadata at `.agents/plugins/marketplace.json` and `plugins/research-codex/.codex-plugin/plugin.json`. The Codex plugin lives in its own `plugins/research-codex/` root with its own skill copy at `plugins/research-codex/skills/research/SKILL.md`, so the existing `npx skills add` and Claude Code plugin paths stay untouched.

Restart Codex after adding the marketplace if the current session does not pick up `/research` immediately. Then invoke it inside Codex:

```text
/research compare durable local memory patterns for code agents
```

### 4. Direct git clone (simplest Claude Code route, works anywhere)

```bash
# Personal (across all your projects)
git clone https://github.com/hec-ovi/research-skill ~/.claude/skills/research

# Or project-only
git clone https://github.com/hec-ovi/research-skill <your-project>/.claude/skills/research
```

Claude Code picks up direct-cloned skills live, no restart needed.

---

## Usage

The skill auto-activates when you ask a research-style question. In Claude Code and the Codex plugin route, you can also invoke it explicitly:

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

`.research/` is a top-level project directory (sibling of `.claude/`, not nested inside it). It's colocated with the project, gitignored by default, and easy to find by name. Reads and writes go through the host's normal permission system.

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

- A code CLI that implements the [SKILL.md format](https://agentskills.io/specification) (Claude Code, Codex, or any other compatible client)
- For Codex plugin installation: Codex CLI with `codex plugin marketplace add`
- For Claude Code Investigation: an Opus-class model accessible to the spawning agent
- For Codex Investigation with subagents: GPT-5.5 with `reasoning_effort: "xhigh"`

---

## Recommended setup

### Claude Code: pin subagents to Opus

The Investigation phase needs reasoning depth. The skill spawns subagents with `model: "opus"`, but the calling agent has to actually pass that parameter on every spawn. To make it systematic across all your Claude Code sessions, configure your environment to default subagents to Opus.

Two practical approaches:

- **Hook (strongest)**: add a `PreToolUse` hook on the `Agent` tool in `~/.claude/settings.json` that blocks any spawn whose `model` field is not `opus`. The hook runs before the tool dispatches, so a non-opus spawn never reaches the API.
- **Convention (lightest)**: add a one-line note to your `~/.claude/CLAUDE.md`: *"Every Agent tool call MUST pass `model: \"opus\"`."* Claude reads CLAUDE.md every session.

Smaller models work fine for the main conversation. The contrarian pass and synthesis steps in Investigation specifically depend on Opus-class reasoning depth; smaller models tend to skip the contrarian phase or produce shallow syntheses.

### Codex: use GPT-5.5 xhigh

The Codex plugin uses a separate Codex-specific skill file at `plugins/research-codex/skills/research/SKILL.md`. That copy tells Codex to use `model: "gpt-5.5"` with `reasoning_effort: "xhigh"` when the user explicitly authorizes subagents. If subagents are not authorized, the Codex skill runs the same investigation phases inline.

---

## Roadmap

### Current activation footprint: ~5,500 tokens, on the heavier side

When the skill activates, the full `SKILL.md` body loads into the main agent's context. As of v0.2.7 the activation cost is approximately 4,500 to 5,500 tokens (depending on tokenizer). The skill registration metadata (frontmatter only, always loaded) is a separate ~130 tokens.

Comparison points:

- Most Vercel `skills.sh` reference skills sit at 500 to 2,000 tokens
- Anthropic reference skills typically run 1,500 to 3,000 tokens
- This skill is roughly double that

The reason is that the Investigation phase is a substantive procedure (5 cognitive phases verbatim, brief checklist, citation rules, required output format, gap handling) and the Storage phase has its own validation rules. The didactic content is real; it earns its keep when Investigation actually runs. But on Retrieval-only calls (the most common path), the agent loads all of it just to get to the loading-hierarchy and lookup-procedure sections.

### Planned: thin-dispatcher refactor (deferred)

The clean architectural answer is to apply progressive disclosure recursively, the same pattern the skill already applies to research data. Specifically: split the single `SKILL.md` into a thin dispatcher plus phase-specific procedure files that load only when their phase is active.

Target structure:

```
research/
├── SKILL.md              # thin dispatcher: when, where, which procedure to load
└── procedures/
    ├── retrieval.md      # loading hierarchy, lookup procedure, INDEX patterns
    ├── investigation.md  # cognitive phases, brief checklist, citation rules, output format
    └── storage.md        # FINDINGS schema, Review-before-storing, conflict handling
```

How it would work mechanically:

1. The agent activates the skill and reads `SKILL.md` (cheap, ~1,500 to 2,000 tokens).
2. `SKILL.md` names which procedure file to load for each phase: *"For Retrieval, read `procedures/retrieval.md`. For Investigation, read `procedures/investigation.md` AFTER deciding mode in Retrieval phase 5. For Storage, read `procedures/storage.md` after Investigation returns."*
3. The agent uses the `Read` tool to pull only the procedure file relevant to the current phase. A pure Retrieval call (read INDEX, sed Summary, answer) never touches `investigation.md` and never pays for it.

This is the same *"thin harness, fat skills"* pattern GBrain uses (`RESOLVER.md` as the dispatcher, individual skill files loaded on demand). Applied here, it's a natural fit because the three phases (Retrieval, Investigation, Storage) are already cleanly separated in the workflow, and the heaviest procedure (Investigation) is also the least-frequent path. Most calls are Retrieval-only.

Expected post-refactor footprint:

- `SKILL.md` (always loaded on activation): ~1,500 to 2,000 tokens
- `procedures/retrieval.md` (loaded on every research-style question): ~800 to 1,200 tokens
- `procedures/investigation.md` (loaded only when fresh research is needed): ~1,500 to 2,000 tokens
- `procedures/storage.md` (loaded only when actually writing): ~800 to 1,200 tokens

A typical Retrieval-only call would pay ~2,500 to 3,200 tokens (SKILL.md + retrieval.md), down from the current ~5,000. An Investigation call would pay roughly the same as today (all phases involved), but at least the cost would be honest: you pay for what you use.

### Why not yet

The skill is working, the size is heavy but not blocking, and there has been no demand from users yet. The repo just launched on 2026-04-25; the only confirmed user is the maintainer, and the maintainer has not hit context-budget pressure on this skill in real workflows. The refactor is a real restructure: probably half a day of careful editing, plus end-to-end testing on every phase (Retrieval new entry, Retrieval merge, Investigation new entry mode, Investigation merge mode, Storage paste path), plus updating the duplicated skill paths and plugin descriptors so subdirectory loading is honored, plus rewriting CHANGELOG and bumping to a minor version (likely `v0.3.0`).

The refactor will be triggered when any of these signals lands:

- A user reports the activation cost as a real friction in their context budget
- A new feature pushes `SKILL.md` past 6,000 tokens
- The procedure content grows organically to the point where the dispatcher spine already feels redundant
- Someone files an issue or PR proposing the split

Until one of those triggers, the single-file structure is the right call: everything is in one place, the file is readable end-to-end, and the load-bearing optimization (progressive disclosure of the actual research data via INDEX, then Summary, then full body) already works as designed. Optimizing the SKILL.md itself before there is felt friction is premature engineering.

If you want to discuss the refactor or volunteer feedback on activation cost in your own usage, open an issue at [github.com/hec-ovi/research-skill/issues](https://github.com/hec-ovi/research-skill/issues).

---

## License

[MIT](LICENSE). Free to use, modify, fork, distribute. Attribution appreciated, not required.
