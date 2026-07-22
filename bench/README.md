# DeepResearch Bench II pilot

A 3-task pilot measuring this skill's investigation brief against a plain research prompt, using the rubrics from [DeepResearch Bench II](https://github.com/imlrz/DeepResearch-Bench-II) (arXiv 2601.08536).

**This is a self-run with a substitute judge. It is not a leaderboard result and is not comparable to one.**

## Method

Tasks 62 (Health), 114 (Software), 80 (History), the three smallest English tasks by rubric count (39, 50, 37 rubrics). Four arms, all on Opus:

- `research-skill`: the SKILL.md investigation brief verbatim (six cognitive phases, effort scaling, citation rules, return-only end anchor).
- `baseline`: the raw task prompt plus "research this and write the report".
- `research-skill-v031`: the same brief after the source-independence rules landed (decompose away from a single named source, trace each claim to its own primary, reproduce the question's requested structure).
- `research-skill-v034`: adds the enumeration rule (rebuild a required list from the items themselves rather than copying an aggregator's table) and the opening rule (state the finding first, name each source where its own contribution appears).

Each report was graded against every rubric item with the benchmark's own three-way rule: 1 satisfied, 0 absent, -1 satisfied but attributed to the task's blocked source article.

The official judge is gemini-2.5-pro. Its free-tier quota is now 0, so grading used Sonnet 5 with the official prompt. A free-tier fallback (gemini-3.1-flash-lite) was tried first and discarded: it marked nearly every rubric satisfied across all six reports, which cannot be right when the published leaderboard tops out near 40% on recall.

## Results

| Arm | Info recall | Analysis | Presentation | Weighted | Blocked items |
|---|---|---|---|---|---|
| research-skill | 34.5% | 17.4% | 70.0% | 33.9% | 75 |
| baseline | 44.3% | 44.1% | 70.0% | 48.1% | 60 |
| research-skill-v031 | 37.4% | 23.6% | 47.8% | 34.1% | 69 |
| research-skill-v034 | 68.2% | 53.0% | 70.0% | 63.2% | 41 |

Weighting is 0.5 / 0.35 / 0.15. The paper says content outweighs presentation but does not publish exact weights, so this split is ours.

The first two skill arms scored below baseline, and the reason is not research quality. Counting blocked items as content-present, all four arms sit between 91% and 94% coverage. Every arm found the required facts. The difference is what each one credits them to.

Every DRB2 task is derived from one expert article, listed in a `blocked` field. Satisfying a rubric item while crediting that article scores -1 instead of +1. The skill's citation rules (name the source in prose, list every URL in a Sources block) make such use trivially detectable, so its reports absorbed more of the penalty. Reading the judges' reasons confirms it: on task 80 all 11 analysis items came back -1 with wording like "explicitly attributed to Budryte's framing rather than presented independently", and on task 62 all 23 recall items were -1 because "the table is explicitly introduced as coming from the blocked Tsai et al. meta-analysis". In each case the judge confirms the content is right before blocking it.

The per-task split is where the v0.3.1 arm earns its keep. On task 114 it is the best of the three on info recall, 27 of 37 against baseline's 25 and the old brief's 19, and it halves blocked items from 18 to 9. That report traced the market-share figures to national competition authorities instead of the blocked OECD paper, which is exactly what the source-independence rule asks for. On task 62 it stayed at 0 of 23, because the harmonized trial-characteristics table exists only inside the blocked meta-analysis: re-attributing it is not enough, the individual trials have to be opened. That gap is what v0.3.4's enumeration rule targets.

Presentation is where v0.3.1 gave points back, dropping to 47.8%. These rubrics grade compliance with each task's own requested structure (a table with a specific caption, a specific number of sub-sections), and the arm that spent its effort on source independence let the requested shape slip.

The v0.3.4 arm leads every dimension, and the mechanism is visible per cell rather than diffuse. Task 62 recall went from 0 of 23 (all 23 blocked, in both earlier skill arms) to 23 of 23 with nothing blocked: the characteristics table was rebuilt row by row from the individual trials, so the judge found each study's country, design, composition, control, baseline pressures and duration present and attributed to the trial rather than to the blocked meta-analysis. Task 114 analysis went to 8 of 8 clean, and task 80 presentation recovered to 3 of 3 from v0.3.1's 1 of 3.

Two cells show the rules are followed unevenly, which is where the remaining headroom sits. On task 114 recall the arm fell to 21 of 37 with 16 blocked, below v0.3.1's 27 of 37, because that report copied the market-share table out of the blocked OECD study instead of rebuilding it from the five national authorities, the exact move the enumeration rule asks the investigation to avoid and which the v0.3.1 run had made correctly. On task 80 the report still opened by naming the blocked essay as the work that draws the three figures together, so the judge blocked every item worded as something that essay quotes or presents, while items traced to the underlying chapter, the subject's own autobiography and independent reviews scored. Coverage is flat across all four arms at 91-94%, so none of this is a change in what the research found; it is entirely a change in what the report credits.

## Caveats

Three tasks, one judge, non-official model. The judge runs applied the blocked rule at visibly different thresholds, and at n=3 one task's interpretation moves the mean. Treat the direction as a signal worth following up, not the magnitude.

## Files

- `aggregate_pilot.py` reads per-report score files and prints the comparison.
- `scores/pilot-2026-07-22.json` holds the raw per-rubric scores for all six reports.

Reproducing a run needs the benchmark repo (tasks and rubrics are CC BY 4.0 there, not vendored here) and a judge model. The evaluator ships pointed at an internal gateway; targeting Google's public API means building the URL per model, sending `x-goog-api-key`, and dropping the `model` field from the payload.
