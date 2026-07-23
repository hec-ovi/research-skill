# Attribution regression harness

Rule changes to the investigation brief are easy to argue about and hard to check. This harness scores them. It grades reports from different versions of the brief against the rubrics from [DeepResearch Bench II](https://github.com/imlrz/DeepResearch-Bench-II) (arXiv 2601.08536), which are useful here because they penalize a specific failure the skill was prone to: getting a fact right and crediting it to the wrong source.

## Method

Three tasks: 62 (Health), 114 (Software), 80 (History), the smallest English tasks by rubric count (39, 50, 37 rubrics). Four arms, all on Opus:

- `research-skill`: the SKILL.md investigation brief verbatim (six cognitive phases, effort scaling, citation rules, return-only end anchor).
- `baseline`: the raw task prompt plus "research this and write the report".
- `research-skill-v031`: the same brief after the source-independence rules landed (decompose away from a single named source, trace each claim to its own primary, reproduce the question's requested structure).
- `research-skill-v034`: adds the enumeration rule (rebuild a required list from the items themselves rather than copying an aggregator's table) and the opening rule (state the finding first, name each source where its own contribution appears).

Each report is graded against every rubric item with the benchmark's three-way rule: 1 satisfied, 0 absent, -1 satisfied but attributed to the task's blocked source article. Every DRB2 task derives from one expert article, listed in a `blocked` field, and crediting that article is what turns a +1 into a -1.

Grading uses Sonnet 5 with the benchmark's own judge prompt, the same judge and the same prompt for every arm, which is what makes the arms comparable to each other. Weighting is 0.5 recall / 0.35 analysis / 0.15 presentation; the paper states content outweighs presentation without publishing exact weights, so this split is ours. An earlier attempt with gemini-3.1-flash-lite was discarded: it marked nearly every rubric satisfied on every report, so it could not separate the arms.

## Results

| Arm | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|
| research-skill | 34.5% | 17.4% | 70.0% | 33.9% | 75 |
| baseline | 44.3% | 44.1% | 70.0% | 48.1% | 60 |
| research-skill-v031 | 37.4% | 23.6% | 47.8% | 34.1% | 69 |
| research-skill-v034 | 68.2% | 53.0% | 70.0% | 63.2% | 41 |

Coverage, which counts blocked items as content-present, sits between 91% and 94% for all four arms. Every arm found the required facts, so the spread between them comes from attribution alone.

What is vendored: the raw per-rubric scores for the `research-skill` and `baseline` rows live in `scores/pilot-2026-07-22.json`, and `python3 bench/aggregate_pilot.py` recomputes those two rows from them (the consistency test fails if the table drifts). The `research-skill-v031` and `research-skill-v034` rows come from the same 2026-07-22 run, but their raw score files were never committed and no longer exist, so those two rows are a recorded result, not a recomputable one. Re-verification with a fresh run is planned in `docs/PLAN.md`.

The first two skill arms scored below a plain research prompt. The judges' reasons say why: on task 80 all 11 analysis items came back -1 with wording like "explicitly attributed to Budryte's framing rather than presented independently", and on task 62 all 23 recall items were -1 because "the table is explicitly introduced as coming from the blocked Tsai et al. meta-analysis". The judge confirms the content is correct, then blocks it. The skill names its sources in prose and lists every URL, which makes its use of the origin article easy for a judge to spot.

v0.3.1 changed how sources were credited. On task 114 that was enough: best of the three arms on recall, 27 of 37 against baseline's 25 and the old brief's 19, with blocked items halved from 18 to 9, because the report traced market shares to national competition authorities instead of the blocked OECD paper. On task 62 it scored 0 of 23 again, since the harmonized trial-characteristics table exists only inside the blocked meta-analysis and the run never opened the individual trials. Presentation slipped to 47.8%, where that arm spent its effort on sourcing and let each task's requested structure drift.

v0.3.4 changed where the rows came from, and leads every dimension. Task 62 recall went from 0 of 23 to 23 of 23 with nothing blocked: the table was rebuilt row by row from the individual trials, and the judge found each study's country, design, composition, control, baseline pressures and duration present and credited to the trial. Task 114 analysis reached 8 of 8 clean and task 80 presentation recovered to 3 of 3.

Two cells in that arm broke rules the brief already contained, which is where the remaining work is. Task 114 recall fell to 21 of 37 with 16 blocked, below v0.3.1, because the report copied the market-share table out of the blocked OECD study rather than rebuilding it from the five national authorities. Task 80 still opened by naming the blocked essay as the work drawing its three figures together, so every item worded as something that essay quotes or presents was blocked, while items traced to the underlying chapter, the subject's own autobiography and independent reviews scored. Both are compliance failures, not gaps in the rules, so v0.3.5 added the matching checks to the storage review.

## Scope

Three tasks, one judge model, three dimensions per task. Judge runs apply the blocked rule at different thresholds, so a single task's reading moves the arm average. Read the per-cell numbers; every conclusion above came from a cell, not from a mean.

These numbers measure arms against each other on one harness. The public DRB2 leaderboard is scored by gemini-2.5-pro, which is not what runs here, so nothing in this table is a position on it.

## Files

- `aggregate_pilot.py` recomputes the comparison from every JSON under `scores/`.
- `scores/pilot-2026-07-22.json` holds the raw per-rubric scores for the vendored arms.
- `tests/check_skill.sh` (repo root) recomputes the table above and fails on drift.

Reproducing a run needs the benchmark repo (tasks and rubrics are CC BY 4.0 there, not vendored here) and a judge model. The evaluator ships pointed at an internal gateway; targeting Google's public API means building the URL per model, sending `x-goog-api-key`, and dropping the `model` field from the payload.
