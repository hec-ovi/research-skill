# Audit and hardening plan (2026-07-23)

Working plan for the current audit pass. Each step is small enough to commit on its own; the progress log at the bottom records what actually happened so the work can resume from any point.

## Audit findings (2026-07-23)

Verified externally where the claim is external; recomputed locally where the claim is numeric.

1. **Bench aggregator does not run from a clone.** `bench/aggregate_pilot.py` reads `judge/<arm>/scored-<idx>.json` and `tasks_and_rubrics.jsonl`, neither of which is in the repo. The vendored `scores/pilot-2026-07-22.json` is never read. The script also only knows 2 of the 4 arms in the README table.
2. **Two of four bench arms are not backed by vendored data.** `scores/pilot-2026-07-22.json` holds `research-skill` and `baseline` only. Recomputing those two arms from the JSON reproduces the README table exactly (34.5 / 17.4 / 70.0 / 33.9 weighted / 75 blocked, and 44.3 / 44.1 / 70.0 / 48.1 / 60). The `v031` and `v034` rows have no raw scores in the repo; the artifacts from the 2026-07-22 run were not vendored and are no longer on disk. Those rows need re-verification or explicit labeling.
3. **README route count mismatch.** Badge says "Install: 3 routes", the Install section says four.
4. **README Roadmap section is stale.** Says the repo "just launched on 2026-04-25" and that the deferred refactor would bump "likely v0.3.0", which already shipped. Section is also far longer than it needs to be.
5. **Spec conformance overstated.** agentskills.io/specification (checked 2026-07-23) defines `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Our `when_to_use`, `user-invocable`, `argument-hint` are Claude Code extensions, not spec fields. README and CHANGELOG imply full conformance.
6. **GBrain citations verified good.** `skills/RESOLVER.md` and `docs/ethos/THIN_HARNESS_FAT_SKILLS.md` both exist in garrytan/gbrain (checked 2026-07-23) and match how the README describes the dispatcher pattern and the thin-harness philosophy.
7. **No fallback when subagent spawning is unavailable.** The Claude skill copies mandate an Agent spawn with `model: "opus"` and background mode. An agent without a working Agent tool (or a small model that fumbles the spawn) has no stated inline path. The Codex copy has one; the Claude copies do not. To confirm with the Haiku end-to-end test.
8. **Opus 4.7 wording is version-pinned.** The skill spawns `model: "opus"` generically; README badge/text and plugin.json name 4.7 specifically. Use version-neutral wording.
9. **No test ties the bench README table to the vendored scores.** Numbers can drift silently.

## Steps

- [x] S1. Commit this plan.
- [x] S2. Bench harness: rewrite `aggregate_pilot.py` to read the vendored scores JSON and print the full table (recall, analysis, presentation, weighted, blocked). Extend `tests/check_skill.sh` to recompute the table and fail on drift against `bench/README.md`.
- [x] S3. Bench docs: state exactly which arms are vendored; label the non-vendored rows as pending re-verification.
- [x] S4. Haiku end-to-end dummy test, run A (cold store): sandbox project, Haiku agent given only the skill file and the prompt "find me the best fps game". Observe setup, WebSearch usage, storage, index row. No extra instructions; the point is minimal-briefing survival.
- [ ] S5. Haiku end-to-end dummy test, run B (warm store): same sandbox, prompt "whats the best coding language for 3d games today" investigated and stored first, then re-asked to check the retrieval stop rule (must answer from Summary without reopening the full entry).
- [ ] S6. SKILL.md fixes from whatever A and B break (expected: inline-investigation fallback when no subagent tool is available). All three Claude copies plus Codex copy, plus test assertions for the new lines.
- [ ] S7. Bench re-verification with own subagents: fetch DRB2 tasks 62 / 114 / 80 and rubrics, regenerate reports for the current brief and baseline arms, judge every rubric item with Haiku subagents using the benchmark's blocked-source rule, vendor reports and scores, update `bench/README.md` with the new run labeled with its judge model.
- [ ] S8. README overhaul: route count, Roadmap prune, spec-conformance wording, version-neutral model wording, reflect the Haiku test results.
- [ ] S9. Version bump + CHANGELOG. Re-check repo description and topics. Full test run and final read-through.

## Progress log

- 2026-07-23: Audit complete, findings 1 to 9 above. Plan committed (S1).
- 2026-07-23: S2 done. `aggregate_pilot.py` reads `bench/scores/*.json` directly (any arms present in the file); recomputed values for the two vendored arms reproduce the README table exactly. `tests/check_skill.sh` now recomputes every vendored arm and fails if the README table row drifts.
- 2026-07-23: S3 done. `bench/README.md` now states which rows are recomputable from vendored scores and which two are a recorded result only, with re-verification pointed at this plan.
- 2026-07-23: S4 done. Run A results in `tests/e2e/README.md`: setup perfect, web search from the small agent works, but triage punted the ambiguous question back to the user, no investigation phases ran, and Storage never happened (no entry, no index row). Three skill fixes queued for S6. Run B (S5) moved after S6 so the stop rule is tested on the patched skill.
