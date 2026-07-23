# Attribution regression harness

Rule changes to the investigation brief are easy to argue about and hard to check. This harness scores them. It grades reports from different versions of the brief against the rubrics from [DeepResearch Bench II](https://github.com/imlrz/DeepResearch-Bench-II) (arXiv 2601.08536), which are useful here because they penalize a specific failure the skill was prone to: getting a fact right and crediting it to the wrong source.

## Method

Three tasks: 62 (Health), 114 (Software), 80 (History), the smallest English tasks by rubric count (39, 50, 37 rubrics). Each report is graded against every rubric item with the benchmark's three-way rule: 1 satisfied, 0 absent, -1 satisfied but attributed to the task's blocked source article. Every DRB2 task derives from one expert article, listed in a `blocked` field, and crediting that article is what turns a +1 into a -1.

Weighting is 0.5 recall / 0.35 analysis / 0.15 presentation; the paper states content outweighs presentation without publishing exact weights, so this split is ours. Both runs use the benchmark's own judge prompt, the same judge for every arm within a run, which is what makes arms comparable to each other. Judges apply the blocked rule at different thresholds across models and runs, so rows are comparable within one table only, never across tables, and nothing here maps to the public DRB2 leaderboard (scored by gemini-2.5-pro).

## Run 1: 2026-07-22, Opus reports, Sonnet 5 judge

Four arms, all reports written by Opus:

- `research-skill`: the SKILL.md investigation brief verbatim (six cognitive phases, effort scaling, citation rules, return-only end anchor).
- `baseline`: the raw task prompt plus "research this and write the report".
- `research-skill-v031`: the same brief after the source-independence rules landed (decompose away from a single named source, trace each claim to its own primary, reproduce the question's requested structure).
- `research-skill-v034`: adds the enumeration rule (rebuild a required list from the items themselves rather than copying an aggregator's table) and the opening rule (state the finding first, name each source where its own contribution appears).

An earlier attempt with gemini-3.1-flash-lite as judge was discarded: it marked nearly every rubric satisfied on every report, so it could not separate the arms.

| Arm | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|
| research-skill | 34.5% | 17.4% | 70.0% | 33.9% | 75 |
| baseline | 44.3% | 44.1% | 70.0% | 48.1% | 60 |
| research-skill-v031 | 37.4% | 23.6% | 47.8% | 34.1% | 69 |
| research-skill-v034 | 68.2% | 53.0% | 70.0% | 63.2% | 41 |

Coverage, which counts blocked items as content-present, sits between 91% and 94% for all four arms. Every arm found the required facts, so the spread between them comes from attribution alone.

What is vendored from this run: the raw per-rubric scores for the `research-skill` and `baseline` rows live in `scores/pilot-2026-07-22.json`, and `python3 bench/aggregate_pilot.py` recomputes those two rows from them (the consistency test fails if the table drifts). The `research-skill-v031` and `research-skill-v034` rows come from the same run, but their raw score files were never committed and no longer exist, so those two rows are a recorded result, not a recomputable one.

The first two skill arms scored below a plain research prompt. The judges' reasons say why: on task 80 all 11 analysis items came back -1 with wording like "explicitly attributed to Budryte's framing rather than presented independently", and on task 62 all 23 recall items were -1 because "the table is explicitly introduced as coming from the blocked Tsai et al. meta-analysis". The judge confirms the content is correct, then blocks it.

v0.3.1 changed how sources were credited. On task 114 that was enough: best of the three skill arms on recall, 27 of 37 against baseline's 25 and the old brief's 19, with blocked items halved from 18 to 9, because the report traced market shares to national competition authorities instead of the blocked OECD paper. On task 62 it scored 0 of 23 again, since the harmonized trial-characteristics table exists only inside the blocked meta-analysis and the run never opened the individual trials.

v0.3.4 changed where the rows came from, and leads every dimension. Task 62 recall went from 0 of 23 to 23 of 23 with nothing blocked: the table was rebuilt row by row from the individual trials. Two cells in that arm still broke rules the brief already contained (task 114 copied the market-share table out of the blocked OECD study; task 80 opened by naming the blocked essay as the work drawing its figures together), which is why v0.3.5 added the matching checks to the storage review.

## Run 2: 2026-07-23, Haiku reports, Haiku 4.5 judge

Re-verification with the smallest tier at both ends: reports written by Haiku agents doing live web research, every rubric item judged by Haiku. Two arms, the v0.3.6 brief and the same baseline prompt. Fully vendored: reports in `reports/pilot-2026-07-23/`, scores in `scores/pilot-2026-07-23-haiku.json`.

| Arm | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|
| research-skill | 37.2% | 57.6% | 36.7% | 44.3% | 6 |
| baseline | 36.3% | 20.8% | 71.7% | 36.2% | 7 |

The skill arm wins on the weighted score, and the gap sits where the source rules aim. On task 114 analysis the baseline lost 6 of 8 items as blocked because its market-structure claims trace to the blocked OECD study; the skill arm, briefed to credit national competition authorities directly, lost 1 and scored 6 of 8. On task 80 analysis the baseline scored 0 of 11 against the skill arm's 8 of 11.

Two cells show the writer model's ceiling rather than the brief. Task 62 recall collapsed for both arms (2 of 23 and 0 of 23): rebuilding the trial-characteristics table requires opening some twenty individual trials and keeping exact compositions, which Haiku writers did not sustain; the Opus-written v0.3.4 run scored 23 of 23 on the same cell with the same rules. This is the measured basis for the skill's recommendation to run Investigation on an Opus-class model. Task 80 presentation (0 of 3, all blocked) is a strict single-judge reading that blocked structure items because the blocked article appears in the source list; the same report took 8 of 11 on analysis.

## Scope

Three tasks per run, one judge model per run, three dimensions per task. A single task's reading moves an arm average, so read the per-cell numbers; every conclusion above came from a cell, not from a mean.

## Files

- `aggregate_pilot.py` recomputes the comparison from every JSON under `scores/`.
- `scores/pilot-2026-07-22.json` holds run 1's per-rubric scores for the vendored arms.
- `scores/pilot-2026-07-23-haiku.json` holds run 2's per-rubric scores, complete.
- `reports/pilot-2026-07-23/` holds run 2's six reports verbatim.
- `tests/check_skill.sh` (repo root) recomputes both tables and fails on drift.

Reproducing a run needs the benchmark repo (tasks and rubrics are CC BY 4.0 there, not vendored here) and a judge. Run 2's judging used the benchmark's judge prompt verbatim inside Claude Code subagents, no external evaluation service required.
