---
name: research
description: Persistent project-scoped store for deep research on large topics. Use for substantive questions - comparing libraries, evaluating tools, surveying solutions to hard problems. Not for plan notes, not for small facts, not for code-level decisions, not for ideas.
when_to_use: User asks a research question that warrants investigation across multiple sources ("what's the latest npm for X", "which 2D engines clone fastest", "compare ORMs for 2026"). Skip for quick lookups, plan-stage notes, or anything that fits in conversation.
user-invocable: true
argument-hint: "<topic>"
---

# Research

Persistent project-scoped store for deep research findings. You activated this skill because the user asked a substantive research question, or invoked it explicitly with `/research <topic>`.

If invoked with a topic argument (e.g. `/research tailwind-v5`), use it as the seed for Retrieval - start by looking up that topic in `INDEX.md`. Don't research blindly; the lookup may answer immediately.

## When to use

- "what's the latest npm package that does X"
- "compare A vs B vs C for 2026"
- "which engines / frameworks / libraries can clone X fast"
- "research how Y works under the hood"
- "deep dive on Z"
- User pastes a long markdown research dump and asks you to save it

## When NOT to use

- Plan-stage notes
- Small facts or one-line preferences
- Code-level decisions tied to one file
- Casual lookups answerable from a single source with no synthesis
- Recording personal ideas or musings
- As a substitute for a single WebSearch or WebFetch

If a single WebSearch + 1-2 sentences answers the question, you don't need this skill.

## Setup (first use only)

On first activation in a project, do this once:

1. Resolve project root: `git rev-parse --show-toplevel 2>/dev/null || pwd`
2. Create `<root>/.research/` if missing
3. Create `<root>/.research/INDEX.md` with this exact content:

   ```markdown
   # Research index

   | Topic | Path | Last verified | One-liner |
   |---|---|---|---|
   ```
4. Add `.research/` to `<root>/.gitignore`. If `.gitignore` doesn't exist, create it. Research data may contain proprietary insights, default private.

The data lives at `<root>/.research/` (sibling of `.claude/`, not nested inside it). It is a top-level project directory chosen so research data is colocated with the project, gitignored by default, and easy to find by name. Auditing remains intact: every read and write goes through the host's normal permission system.

## Workflow

### 1. Retrieval (the read side - this is how the skill saves your context)

The whole point of this system is **progressive disclosure**: don't load what you don't need. `INDEX.md` is your dispatcher - it lets you decide which entries to load *without paying to load them*. Walk the hierarchy from cheapest to most expensive; only escalate when the previous tier doesn't answer the question.

#### Loading hierarchy (cheapest → most expensive)

| Tier | Load | Approx tokens | When |
|---|---|---|---|
| 1 | `INDEX.md` (always) | ~100-500 | Every retrieval - your routing table |
| 2 | Entry's `## Summary` only | ~50-200 | When the index shows a topic match |
| 3 | Full `FINDINGS.md` body | ~500-3000 | When Summary doesn't cover the question |
| 4 | Specific `raw/<file>` document | varies (often heavy) | When a finding cites it and you need to verify a claim |
| 5 | Cross-referenced entry (`related:`) | repeats tiers 2-3 | When the question spans entries |

#### Lookup procedure

1. **Read `INDEX.md` first** (tier 1). Scan the one-liner summary column against the user's question. This is the dispatcher - same role as `RESOLVER.md` in GBrain.

2. **Match decision:**
   - **Strong match** - one entry's one-liner clearly covers the topic → go to step 3 with that entry.
   - **Multiple plausible matches** - load `## Summary` of each (still cheap at tier 2). Pick the one(s) that actually answer.
   - **Weak / no match** → fall through to Investigation. A new entry will be added.

3. **Read only the matched entry's `## Summary`** (tier 2):
   ```bash
   sed -n '/^## Summary/,/^## /p' <root>/.research/<slug>/FINDINGS.md
   ```
   Usually enough.

4. **Escalate one tier only when needed:**
   - Question needs claims-level detail beyond the Summary → load the full `FINDINGS.md` body (tier 3).
   - Question is "have we tried X before / what was discarded?" → `sed` just that section: `sed -n '/^## Discarded approaches/,/^## /p' <root>/.research/<slug>/FINDINGS.md`. Don't load the rest.
   - Question references a paste-cited claim → open that specific file under `raw/` (tier 4).
   - Question spans topics covered by separate entries → follow `related:`, repeat tiers 2-3 on each.

5. **Fall through to Investigation. Pick the mode:**
   - **No entry exists** in `INDEX.md` → Investigation in **new entry mode**.
   - **Existing entry doesn't actually resolve the question** (problem still unsolved) → Investigation in **merge mode** (pass existing entry content to the subagent).
   - **Existing entry is stale** on a fast-moving topic → Investigation in **merge mode** (refresh, don't quote).

#### What NEVER to do

- **Don't load everything.** The schema exists so you can be selective.
- **Don't load the full body when Summary suffices.** If 3 lines answer it, don't pull 300.
- **Don't load raw documents speculatively.** They're heavy; most questions don't need them.
- **Don't re-read an entry you already loaded this session** - unless it was updated since.

#### `INDEX.md` as dispatcher

`INDEX.md` exists *only* so you can decide which entries to load without loading them. The one-liner column is the entire signal you have before paying for an entry read - write it specifically when storing.

Keep `INDEX.md` tight: under ~100 rows. If it grows beyond that, prune or archive. The whole token-saving design collapses if `INDEX.md` itself becomes a bloat source.

### 2. Investigation (when fresh research is needed)

Spawn a `general-purpose` subagent with `model: "opus"` and **`run_in_background: true`**. The Investigation phase needs a strong model: the contrarian pass and synthesis steps depend on reasoning depth that smaller models won't deliver. Background mode keeps the conversation interactive: the user can keep working while research runs. Storage runs asynchronously when the agent's completion notification arrives.

**The subagent does research and returns its synthesis as structured text. It does NOT write any files.** You (main agent) handle all file writes in Storage. This split keeps responsibility clean: the subagent has zero context and doesn't need to know your schema or `INDEX.md` layout.

**Naming convention.** Set the Agent tool's `description` parameter to `Research investigation: <topic>` (3 to 5 words). This makes research-skill spawns identifiable in the harness UI.

**On completion notification:** parse the agent's return, apply Storage immediately, surface a brief notice to the user (e.g. *"research on `<topic>` saved to `<path>`"*). Do not dump the full findings into chat unless asked.

**Subagents have zero prior context.** They don't see this skill, CLAUDE.md, or our conversation. Brief them completely. **There is no continuation in this harness** - the `SendMessage` tool to resume an agent is not available. One-shot only. If gaps remain, re-spawn with a refined brief.

The mode (new entry vs merge) was decided in Retrieval phase 5. Brief the subagent accordingly:

- **New entry mode** - standard brief, no existing context to feed.
- **Merge mode** - paste the existing entry's `## Summary` and any relevant `## Findings` sections into the brief, marked clearly as *"current state of the entry - verify, update, or supersede"*. Tell the subagent to flag claims that are now wrong.

#### Brief checklist

Every Investigation brief MUST include:

- "You have zero prior context" preamble
- Today's actual date (run `date +%Y-%m-%d` first; pass the literal string)
- Year-pinning rule for WebSearch queries (don't trust the subagent's model prior on what year it is)
- At least 2 independent sources per non-trivial claim. Sources are gathered into a single `## Sources` block at the end of the return; do NOT cite inline.
- The cognitive phases below as explicit numbered steps
- The subagent's required output format (below)
- The strict no-`[n]` / no-inline-URL rule for the Findings body (see Required output format)
- **Merge mode only**: the existing entry content the subagent should verify / supersede

#### Cognitive phases (include verbatim in the subagent brief)

The subagent walks these as discrete phases. Phase 4 is load-bearing:

1. **Decompose** - list sub-claims that would resolve the question; identify what evidence settles each.
2. **Gather** - for each sub-claim, find ≥2 independent sources (year-pinned WebSearch → WebFetch on top results). Quote verbatim. Don't synthesize yet.
3. **Validate** - re-derive numbers, benchmarks, version claims. Flag anything that fails.
4. **Contrarian pass** - actively search for "why is this wrong / scam / criticized / deprecated / known-bad". State the strongest objection found. **Skipping this is the most common subagent failure mode.** Call it out explicitly in the brief.
5. **Synthesize** - verdict + citations + residual disagreements listed explicitly. No silent picks.

#### Required subagent output format

The brief MUST include explicit citation rules. Subagents trained on academic-style writing default to `[1]`, `[2]` inline citations; without explicit instructions they will produce noisy output. State the rules in plain language. Recommended verbatim block to paste into the brief:

> **Citation rules. Read carefully and follow exactly:**
>
> - Do NOT use `[n]` numbered citations. No `[1]`, `[2]`, or any bracketed numbers in the Findings body.
> - Do NOT put URLs in the Findings body.
> - Do NOT add inline footnote markers, anchors, or any per-claim citation tags of any kind.
> - Write Findings as plain prose paragraphs.
> - When a claim's interpretation depends on which source said it, name the source as prose, no brackets ("per the README", "according to littlemight.com", "the HN-simulator commenter argues..."). No URL, no `[n]`.
> - Put ALL sources in a single `## Sources` block at the END of the return, one bullet per source: `- url - fetched YYYY-MM-DD`. The main agent lifts this block to FINDINGS.md frontmatter.
> - Source-count discipline is preserved: at least 2 independent sources per non-trivial claim. The discipline lives in source count, not in inline tagging.

Required output shape (what the subagent returns):

```
## Summary
3 to 6 lines TL;DR.

## Findings
Plain prose. No `[n]` markers. No inline URLs. Inline source-naming as prose only when load-bearing for interpretation.

## Strongest objection (from contrarian pass)
1 to 2 sentences, or "none found".

## Sources
- url - fetched YYYY-MM-DD
- url - fetched YYYY-MM-DD

## (Merge mode only) Supersedes
- claim from existing entry that is now wrong + reason
```

The subagent does not write any files. You parse this return and apply Storage rules.

#### Gap handling

If the subagent's return has gaps:

- **Small gap** (one missing fact, one specific angle) → fill it yourself with a focused WebSearch / WebFetch. Cheaper than re-spawn.
- **Large gap** (whole sections shallow, contrarian pass clearly skipped) → re-spawn with a refined brief that names the specific gap. The previous return is discarded (no file was written yet).

### 3. Storage (the write side - main agent owns ALL file writes)

#### Review before storing

The subagent's structured format does not validate substance. The format only signals "I followed the template"; it does not confirm the content is correct, well-sourced, or relevant to what was asked. Before applying Storage, run this 4-point check:

1. **Relevance**: does the Summary actually answer what was asked? If the agent disambiguated an ambiguous topic (picked one interpretation of several), confirm it matches the user's intent. If wrong, re-spawn with a tighter brief; do not store.
2. **Source quality**: count primary URLs vs aggregated WebSearch snippets in the `## Sources` block. If most sources are search-result summaries without specific fetched URLs, the entry is weaker than it looks. Either fill primaries yourself with focused WebFetch, or store but flag the weakness explicitly in `## Open questions`.
3. **Contrarian pass evidence**: "none found" is rare on any non-trivial topic. If you got "none found", be skeptical: either the topic is genuinely uncontroversial (rare), or the subagent skipped phase 4 (common). If skipped, fill in yourself with focused contrarian searches, or re-spawn.
4. **Citation cleanup**: if the return contains `[n]` markers in the Findings body despite the brief's no-`[n]` rule, strip them before writing FINDINGS.md. This is a known failure mode (subagents fall back to academic citation habits). Do not push the noise downstream. Same for inline URLs in the Findings body: strip them. Sources belong in frontmatter.

If the review surfaces fixable gaps, fill them yourself with a focused WebSearch / WebFetch (cheaper than re-spawn). If gaps are systemic, re-spawn with a refined brief; do not write a half-formed entry.

#### Apply Storage

After Investigation returns its synthesis (or the user pastes findings), you (main agent, never the subagent) finalize the data layer. Two paths, picked based on the mode chosen in Retrieval phase 5:

**New entry path:**

1. Create `<root>/.research/<topic-slug>/`.
2. Write `FINDINGS.md` using the schema in File schemas. Frontmatter: `created` and `last_verified` = today; `status: active`; `sources` from the subagent return; `raw:` omitted (no raw yet); `related: []` unless cross-links apply.
3. Read `INDEX.md`, append a row: topic, path, today's date, a specific one-liner.

**Merge path:**

1. Read the existing `FINDINGS.md`.
2. Update frontmatter: `last_verified` = today; append new sources.
3. **Apply the subagent's `## Supersedes` list:** move each named claim from `## Findings` to `## Discarded approaches` with date + reason. See Conflict handling.
4. Update / extend `## Findings` with new claims.
5. Append a `## Timeline` entry summarizing the change.
6. Read `INDEX.md`, update the row's `Last verified` column. Update the one-liner if the picture has changed.

Use kebab-case slugs that match how the user is likely to ask again - e.g. `tailwind-v5`, `2d-engines-clonable`, `orm-comparison-2026`. The slug should disambiguate.

### 4. Pasted content from the user

If the user pastes a long document and asks you to save it:

1. **Decide path first.** Read `INDEX.md`. Does this paste extend an existing topic (merge mode), or is it a new topic (new entry mode)? Same decision as Retrieval phase 5.
2. Save the raw document verbatim to `<root>/.research/<topic-slug>/raw/<YYYY-MM-DD>-paste.<ext>` (preserve the original extension - `.md`, `.pdf`, `.txt`, `.html`, etc.). If the user pasted text directly with no original file, default to `.md`.
3. Synthesize the content into the same shape the subagent would return (Summary / Findings / Sources). Citations to the raw file: `[Source: raw/<filename>]`.
4. **Apply Storage** (new entry path or merge path from Section 3) using the synthesized content. When writing the entry, include this raw in the `raw:` frontmatter list (path, note, added date).
5. **Offer** to delete the original file: "Save this as research and remove the original at `<path>`?". Always ask. Never auto-delete.

If the user provides only synthesized findings (no raw file worth keeping), skip step 2 and the `raw:` frontmatter entry - just synthesize and apply Storage.

Only create the `raw/` subfolder when there's actually something to save in it.

## Best practices

These are cross-cutting rules. Apply them throughout the workflow.

### Date and freshness

- **Always run `date +%Y-%m-%d` first.** Pin the actual current year in WebSearch queries ("X 2026", "X latest 2026"). Don't trust your model's prior on what year it is.
- Prefer official release notes and changelogs over blog posts.
- When a source is older than 30 days on a fast-moving topic (npm packages, framework releases, AI tooling), treat it as a hint, not canon. Cross-check against newer sources.
- If an existing entry's `last_verified` is older than 30 days on a fast-moving topic, refresh before answering - don't quote a stale entry as current truth.

### Version preference

When recommending a version of a library, framework, or tool:

- **Default = latest stable production release.** That's what users should run unless they ask for something else.
- **LTS** when the project ships one and the user is on a long-lived stack (Node, Postgres, etc.).
- **Nightly / pre-release / alpha / beta builds**: only when the user explicitly asks ("what's coming in next release", "any unreleased features that solve X", "give me the bleeding edge"). Don't recommend nightly as a default - it's unstable and changes daily.
- Always state the version number you're recommending (e.g., "Drizzle ORM 1.4.2" not just "Drizzle ORM").

### Source preference

Higher → lower authority for technical claims:

1. Official documentation / release notes / changelog
2. Maintainer blog posts and conference talks
3. GitHub issues, discussions, and pull request descriptions
4. Recent third-party benchmarks and reviews
5. Stack Overflow / Reddit / random blog posts

Always record `fetched: YYYY-MM-DD` next to each source URL.

### Citation discipline

- Every concrete claim has a `[n]` citation tied to a source URL in `sources` frontmatter
- If you don't have a source, write "no source - open question" and add it to `## Open questions`. Never invent a URL or quote.
- When sources disagree, cite both and note the disagreement explicitly. Don't silently pick one.

### Conflict handling

When new evidence contradicts an existing entry:

1. **Move the old claim to `## Discarded approaches`** with a one-line reason and date. Never delete silently.
2. **If the same approach has failed twice or more**, flag it loudly in `## Findings`: *"approach X has been tried and discarded N times - current working answer is Y"*. The point is to prevent re-trying refuted approaches in future sessions.
3. Update `last_verified` and append a `## Timeline` entry summarizing the change.

## File schemas

### `INDEX.md`

```markdown
# Research index

| Topic | Path | Last verified | One-liner |
|---|---|---|---|
| <topic-slug> | <topic-slug>/FINDINGS.md | YYYY-MM-DD | <one-line summary that disambiguates> |
```

The one-liner is what future-you scans to decide whether to load the entry. Make it specific.

### `FINDINGS.md`

```markdown
---
topic: <slug>
created: YYYY-MM-DD
last_verified: YYYY-MM-DD
status: active                 # active | superseded
related: []                    # other entry slugs for cross-reference
sources:
  - url: https://...
    fetched: YYYY-MM-DD
raw:                           # omit if no raws were saved
  - path: raw/2026-04-25-paste.pdf
    note: user pasted vendor whitepaper
    added: 2026-04-25
---

# <Topic name>

## Summary

3-6 lines. The TL;DR. Loads first on lookup; should answer the common question alone.

## Findings

Plain prose. No `[n]` markers. No inline URLs. When a claim's interpretation depends on which source said it, name the source as prose ("per the README", "according to littlemight.com", "the HN-simulator commenter notes"). For raw documents, refer descriptively ("the pasted whitepaper"); the `raw:` frontmatter has the file path. Frontmatter `sources:` is the bibliography.

## Discarded approaches

| Approach | Why dropped | Date |
|---|---|---|

## Open questions

- ...

## Timeline

- YYYY-MM-DD - initial entry
```

Notes on the schema:
- `raw:` is a list - one entry can accumulate multiple raw documents over time (e.g., user pastes a whitepaper, then later a different report on the same topic). Add new items, don't overwrite.
- Omit the `raw:` key entirely when there are no raw documents - don't leave an empty list.
- `related:` cross-links to other entry slugs. Use this when entries touch overlapping projects but answer different questions (e.g., `knowledge-graphs-comparison` and `mempalace-legitimacy` both mention mempalace but have different scopes - link them, don't merge them).

## Anti-patterns

- **Entry spam**: one topic = one entry. Don't create separate entries for sub-aspects; nest them as sections.
- **Researching the skill itself**: don't write meta-entries about how research-memory works.
- **Hallucinated sources**: never invent URLs or quotes. If WebFetch failed, say so.
- **Auto-delete on paste handler**: always offer, never act.
- **Silent supersede**: any change to a prior conclusion goes through `## Discarded approaches` + `## Timeline`. Never overwrite.
