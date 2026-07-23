<h1 align="center">research-skill</h1>

<p align="center">
  <strong>Persistent project-scoped store for deep research findings, with progressive disclosure and contrarian-pass investigation.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Live-brightgreen" alt="Status" />
  <img src="https://img.shields.io/badge/Version-0.4.1-blue" alt="Version" />
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
  <img src="https://img.shields.io/badge/Investigation-Async_Opus_subagents-9A48A6" alt="Async investigation" />
  <img src="https://img.shields.io/badge/Disclosure-Progressive-FF6B6B" alt="Progressive disclosure" />
  <img src="https://img.shields.io/badge/Inspired_by-Grok_+_GBrain-E63946" alt="Inspirations" />
  <img src="https://img.shields.io/badge/Install-4_routes-2496ED" alt="Install routes" />
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
- **Subagent-isolated investigation.** Heavy web research can run in a separate subagent: an Opus-class model in Claude Code, or GPT-5.5 xhigh in Codex when subagents are explicitly authorized. Your main context stays clean. Hosts without subagents run the same phases inline; the skill states the fallback explicitly.
- **Async where supported.** In Claude Code, the investigation subagent runs in background mode (`run_in_background: true`) so the conversation stays interactive while research happens. In Codex, the plugin investigates inline unless the user explicitly authorizes subagents.
- **Cognitive phases.** Decompose, Gather, Validate, **Contrarian pass**, **Insight extraction**, Synthesize. The contrarian pass actively searches for "why this is wrong" rather than confirming; the insight pass forces causal and comparative claims that go beyond restating facts. Both earn their keep.
- **Two depths: research and deep research.** Fresh questions are triaged at retrieval: **quick** (3 to 6 searches, minutes) for narrow lookups, **deep** (the full 6-phase walk) for comparisons and anything costly to get wrong. Your wording overrides the triage in both directions; a quick entry is stored with `depth: quick` and upgrades through a deep merge later.
- **Small-model tested.** The ambiguous-question rule and the storage rule exist because Haiku-class agents actually broke without them; the retrieval stop rule was then verified holding on the same tier. The failing runs and the passing re-runs on the patched skill are logged in [tests/e2e/](tests/e2e/).
- **Source rules earned on a benchmark, not guessed.** Tracing claims to primaries and rebuilding a required list from the items themselves came out of scored runs against [DeepResearch Bench II](bench/) rubrics, not from taste. See the Benchmarks section below for the numbers.

---

## Benchmarks

The skill is scored against [DeepResearch Bench II](https://agentresearchlab.com/benchmarks/deepresearch-bench-ii/index.html), the same public benchmark whose leaderboard ranks commercial deep-research systems. The most complete run (2026-07-23) has Haiku 4.5 and Sonnet 5 agents writing reports on three DRB2 tasks, all graded by an Opus 4.8 judge using the benchmark's own three-way rubric prompt (a rubric item scores +1 satisfied, 0 absent, -1 satisfied but attributed to the task's blocked source article). Weighting is 0.5 recall / 0.35 analysis / 0.15 presentation.

| Arm | Writer | Info recall | Analysis | Presentation | Weighted | Blocked |
|---|---|---|---|---|---|---|
| research-skill | Haiku 4.5 | 55.5% | 65.9% | 88.9% | **64.2%** | 1 |
| baseline (bare prompt) | Haiku 4.5 | 41.9% | 58.0% | 100.0% | 56.2% | 0 |

The skill brief beats the bare-prompt baseline by 8 weighted points on the same model and the same judge, carried by information recall (55.5% vs 41.9%) and analysis (65.9% vs 58.0%). The analysis gap concentrates on the memory-politics task, where the skill arm scored 8 of 11 rubric items to the baseline's 4 of 11.

For context, not a placement: the public leaderboard's top system scores 64.38% weighted and its median sits near 50%. This run is 3 of 132 tasks under an Opus judge rather than the leaderboard's own scorer, so it is a directional signal that the brief lands a small Haiku agent's report in the top band, not a leaderboard rank. The sharpest finding is that a Sonnet writer scored *lower* (57.5%) because one opening sentence credited a rebuilt table to its blocked source, voiding 30 otherwise-correct rubric items, which is exactly the failure the skill's own source rules target. Full settings, all three arms, every report, and the judge's per-item reasoning are in [`bench/`](bench/).

---

## How findings reach your conversation

When a Claude Code Investigation subagent finishes, its full structured return (Summary, Findings, contrarian objection, sources) is injected into the main agent's context as a task-notification message. No file round-trip, no tail-the-log polling. The main agent parses the return directly and writes the data layer. In Codex, the same structured shape is used, either from an explicitly authorized subagent or from inline investigation.

Why this matters:

- **No raw web-search dump pollution.** The main agent only sees the agent's clean synthesized output, never the raw web search results or fetch responses. Those stay in the subagent's own context and never reach the main agent.
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

The folder layout and the `name` and `description` frontmatter fields follow the open [Agent Skills specification](https://agentskills.io/specification) (Apache 2.0 / CC-BY-4.0). The remaining frontmatter (`when_to_use`, `user-invocable`, `argument-hint`) is a Claude Code extension the spec does not define; hosts that only read the spec fields still get a valid skill. Portable across Claude Code and any other code CLI that implements the SKILL.md format.

### Grok deep-research multi-agent pattern (xAI)

The Investigation phase walks a 6-step cognitive workflow (Decompose, Gather, Validate, Contrarian pass, Insight extraction, Synthesize) adapted from xAI's published [Multi-Agent architecture](https://docs.x.ai/developers/model-capabilities/text/multi-agent) and the [DeepSearch announcement](https://x.ai/news/grok-3). xAI ships 4 specialized agents (Captain, Harper, Benjamin, Lucas) on a shared backbone; this skill condenses those into cognitive phases a single subagent walks from one self-contained brief.

The Contrarian pass (phase 4) is the standout borrowed element: actively searching for "why this is wrong" rather than confirming. In an A/B test on a celebrity-fronted AI tool legitimacy question, the contrarian pass surfaced significant controversy that a minimal-brief baseline missed.

### GBrain RESOLVER pattern (Garry Tan)

`INDEX.md` acts as a dispatcher in the same role as [`RESOLVER.md`](https://github.com/garrytan/gbrain/blob/master/skills/RESOLVER.md) in [GBrain](https://github.com/garrytan/gbrain). The INDEX is scanned first; full entries load only on match. Progressive disclosure tiers borrow GBrain's "thin harness, fat skills" philosophy ([`THIN_HARNESS_FAT_SKILLS.md`](https://github.com/garrytan/gbrain/blob/master/docs/ethos/THIN_HARNESS_FAT_SKILLS.md)).

---

## Schema

Every entry's `FINDINGS.md` has structured frontmatter (`topic`, `created`, `last_verified`, `status`, `depth`, `related`, `sources`, `raw`) and a body with `## Summary`, `## Findings`, `## Insights`, `## Strongest objection`, `## Discarded approaches`, `## Open questions`, `## Timeline`. See [`SKILL.md`](SKILL.md) for the full schema and rules.

## Tests

```bash
bash tests/check_skill.sh
```

Checks that the three Claude skill copies are byte-identical, all four skill files keep the required sections, rules, and schema invariants, the version is consistent across plugin manifests, README, and CHANGELOG, and the bench table in `bench/README.md` matches the vendored scores. `tests/e2e/` documents the manual small-model end-to-end harness and its run log.

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

Activation loads the full `SKILL.md` body, roughly 7,000 to 8,000 tokens (the 32 KB file at about 4 characters per token). That is heavy for a skill (typical reference skills run 500 to 3,000), and most of the weight is the Investigation procedure, which Retrieval-only calls never use.

The planned fix is a thin-dispatcher refactor: split `SKILL.md` into a small dispatcher plus `procedures/retrieval.md`, `procedures/investigation.md`, and `procedures/storage.md`, loaded only when their phase runs. Same "thin harness, fat skills" pattern GBrain applies with `RESOLVER.md`, and the same progressive disclosure this skill already applies to research data. A Retrieval-only call would drop to roughly half the current activation cost.

Deferred until the cost shows up as real friction: a user reporting context pressure, or an issue or PR proposing the split. Feedback welcome at [github.com/hec-ovi/research-skill/issues](https://github.com/hec-ovi/research-skill/issues).

---

## License

[MIT](LICENSE). Free to use, modify, fork, distribute. Attribution appreciated, not required.
