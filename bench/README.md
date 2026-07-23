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

## Run 3: 2026-07-23, Haiku and Sonnet reports, Opus 4.8 judge

The most thorough run, and the one to read first. Everything is vendored: reports in `reports/opus-2026-07-23/`, per-rubric scores in `scores/opus-2026-07-23.json`, and the judge's raw per-item JSON (score, reason, evidence for every rubric) in `judge-raw/opus-2026-07-23/`.

### Exact settings

- **Benchmark**: DeepResearch Bench II, the same public benchmark on the [Agent Research Lab leaderboard](https://agentresearchlab.com/benchmarks/deepresearch-bench-ii/index.html) (132 tasks, 22 domains, 9,430 rubrics). We run 3 tasks: 62 (Health, salt-substitute RCT review), 114 (Software, cloud IaaS/PaaS competition), 80 (History, Eastern-European memory politics), the smallest English tasks by rubric count.
- **Tasks and rubrics**: pulled from the benchmark's `tasks_and_rubrics.jsonl` (CC BY 4.0, not vendored here). Each task carries a `blocked` field naming the single expert article it derives from.
- **Report writers, three arms**:
  - `research-skill-haiku`: the v0.4.1 investigation brief, executed by a Haiku 4.5 agent with live web search.
  - `baseline-haiku`: the raw task prompt plus "research this and write the report", same Haiku 4.5.
  - `research-skill-sonnet`: the same v0.4.1 brief, executed by a Sonnet 5 agent with live web search.
- **Judge**: Opus 4.8, one agent per (arm, task, dimension), 27 gradings. Each judge gets the benchmark's own three-way prompt verbatim (score 1 satisfied, 0 absent, -1 satisfied but the supporting sentence cites the blocked article) plus that task's rubric items and blocked field. Same judge model and same prompt for every arm, which is what makes the arms comparable.
- **Scoring**: rubric pass rate per dimension; weighted 0.5 recall / 0.35 analysis / 0.15 presentation. The paper states content outweighs presentation without publishing exact weights, so this split is ours and is applied identically to all arms.
- **No external service**: writers and judges are all subagents; the only outside dependency is the models and live web search.

### Results

| Arm | Writer | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|---|
| research-skill-haiku | Haiku 4.5 | 55.5% | 65.9% | 88.9% | 64.2% | 1 |
| research-skill-sonnet | Sonnet 5 | 52.8% | 61.5% | 63.9% | 57.5% | 36 |
| baseline-haiku | Haiku 4.5 | 41.9% | 58.0% | 100.0% | 56.2% | 0 |

The skill brief beats its own baseline by 8.0 weighted points on the same writer model and the same judge, the same direction and roughly the same margin the Haiku-judged run 2 found. The gap is where the source rules aim: on task 114 the baseline scored 7/8 analysis but the skill arm matched it while tracing market shares to national competition authorities instead of the blocked OECD study; on task 80 the skill arm took 8/11 analysis to the baseline's 4/11.

For external context only: the public leaderboard's top entry (AI21-DeepResearch) sits at 64.38% weighted and the median around 45%. Our 64.2% is on 3 of 132 tasks under an Opus judge rather than the leaderboard's gemini-2.5-pro, so it is not a leaderboard placement, only a sign the brief lands a full-system deep-research agent's report quality on a small slice.

### The Sonnet arm's 36 blocked items are the sharpest finding

The stronger writer scored lower, and the raw judge JSON says exactly why. All 36 blocked items are on task 62, and 30 of them come from a single sentence. Sonnet rebuilt the 23-trial characteristics table row by row from the individual trials (the enumeration rule working), then opened the table with "This 23-trial list is the enumeration reported by Tsai and colleagues" (the blocked meta-analysis). Opus read that one attribution sentence as sourcing the whole table to the blocked article and returned -1 on all 23 recall rows plus the analysis and presentation items that lean on the table. This is the exact failure the skill's own v0.3.5 storage-review rule names: "an opening sentence that hands the whole answer to a single work before any finding is stated." A more capable writer produced better-sourced content and still tripped the rule, which is the strongest evidence in this repo that the opening-attribution rule is load-bearing and that enforcement, not just wording, is what it needs. On the other two tasks Sonnet is clean (task 114: zero blocked, its own methodology note shows it deliberately avoided the blocked OECD paper and even caught an unsourced figure the Haiku arm had invented). Strip task 62 and the Sonnet arm leads every dimension.

## Scope

Three tasks per run, one judge model per run, three dimensions per task. A single task's reading moves an arm average, so read the per-cell numbers and the raw judge JSON; every conclusion above came from a cell, not from a mean. Judges apply the blocked rule at different thresholds across models, so rows are comparable within one run's table only, never across runs, and none of these numbers is a position on the public leaderboard.

## Files

- `aggregate_pilot.py` recomputes every table from the JSONs under `scores/`.
- `scores/opus-2026-07-23.json` holds run 3's per-rubric scores (Opus judge), complete.
- `scores/pilot-2026-07-23-haiku.json` holds run 2's per-rubric scores (Haiku judge), complete.
- `scores/pilot-2026-07-22.json` holds run 1's per-rubric scores for its two vendored arms.
- `reports/opus-2026-07-23/` holds run 3's nine reports verbatim; `reports/pilot-2026-07-23/` holds run 2's six.
- `judge-raw/opus-2026-07-23/` holds the Opus judge's per-item output (score, reason, evidence) for all 27 gradings.
- `tests/check_skill.sh` (repo root) recomputes every vendored table and fails on drift.

Reproducing a run needs the benchmark repo (tasks and rubrics are CC BY 4.0 there, not vendored here) and a judge model. Runs 2 and 3 judged with the benchmark's prompt verbatim inside subagents, no external evaluation service.
