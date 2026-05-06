# /research

Use the bundled Codex research skill to recall, refresh, or store project-scoped research.

## Arguments

- `topic`: research topic or question.

## Workflow

1. Treat the user argument as the research topic.
2. Follow `skills/research/SKILL.md`.
3. Start with retrieval: inspect `.research/INDEX.md`, then load only matching summaries.
4. If fresh research is needed, use Codex web search and browsing tools for current sources.
5. Use Codex subagents only when the user explicitly asked for subagents, delegation, or parallel agent work; otherwise investigate inline.
6. Store findings under `.research/` using Codex-safe file edits.
