# DeepResearch Bench II pilot

A 3-task pilot measuring this skill's investigation brief against a plain research prompt, using the rubrics from [DeepResearch Bench II](https://github.com/imlrz/DeepResearch-Bench-II) (arXiv 2601.08536).

**This is a self-run with a substitute judge. It is not a leaderboard result and is not comparable to one.**

## Method

Tasks 62 (Health), 114 (Software), 80 (History), the three smallest English tasks by rubric count (39, 50, 37 rubrics). Two arms, both on Opus:

- `research-skill`: the SKILL.md investigation brief verbatim (six cognitive phases, effort scaling, citation rules, return-only end anchor).
- `baseline`: the raw task prompt plus "research this and write the report".

Each report was graded against every rubric item with the benchmark's own three-way rule: 1 satisfied, 0 absent, -1 satisfied but attributed to the task's blocked source article.

The official judge is gemini-2.5-pro. Its free-tier quota is now 0, so grading used Sonnet 5 with the official prompt. A free-tier fallback (gemini-3.1-flash-lite) was tried first and discarded: it marked nearly every rubric satisfied across all six reports, which cannot be right when the published leaderboard tops out near 40% on recall.

## Results

| Arm | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|
| research-skill | 34.5% | 17.4% | 70.0% | 33.9% | 75 |
| baseline | 44.3% | 44.1% | 70.0% | 48.1% | 60 |

Weighting is 0.5 / 0.35 / 0.15. The paper says content outweighs presentation but does not publish exact weights, so this split is ours.

The skill scored worse, and the reason is not research quality. Counting blocked items as content-present, the two arms tie: 100% info recall each, 94.4% vs 95.2% overall coverage. Both found the required facts. The difference is that the skill attributes them.

Every DRB2 task is derived from one expert article, listed in a `blocked` field. Satisfying a rubric item while crediting that article scores -1 instead of +1. The skill's citation rules (name the source in prose, list every URL in a Sources block) make such use trivially detectable, so its reports absorbed more of the penalty. On task 62 the blocked article is the only source carrying the requested trial-characteristics table, and both arms were near-zeroed on recall.

Presentation tied at 70%, and both arms lost points the same way: these rubrics grade compliance with each task's own requested structure (a table with a specific caption, a specific number of sub-sections), which a fixed output template does not provide.

## Caveats

Three tasks, one judge, non-official model. The six judge runs applied the blocked rule at visibly different thresholds, and at n=3 one task's interpretation moves the mean. Treat the direction as a signal worth following up, not the magnitude.

## Files

- `aggregate_pilot.py` reads per-report score files and prints the comparison.
- `scores/pilot-2026-07-22.json` holds the raw per-rubric scores for all six reports.

Reproducing a run needs the benchmark repo (tasks and rubrics are CC BY 4.0 there, not vendored here) and a judge model. The evaluator ships pointed at an internal gateway; targeting Google's public API means building the URL per model, sending `x-goog-api-key`, and dropping the `model` field from the payload.
