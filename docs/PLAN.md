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
- [x] S5. Haiku end-to-end dummy test, run B (warm store): re-ask a stored question with a fresh agent to check the retrieval stop rule (must answer from Summary without reopening the full entry). Run C: second cold prompt "whats the best coding language for 3d games today".
- [x] S6. SKILL.md fixes from whatever A and B break (expected: inline-investigation fallback when no subagent tool is available). All three Claude copies plus Codex copy, plus test assertions for the new lines.
- [x] S7. Bench re-verification with own subagents: fetch DRB2 tasks 62 / 114 / 80 and rubrics, regenerate reports for the current brief and baseline arms, judge every rubric item with Haiku subagents using the benchmark's blocked-source rule, vendor reports and scores, update `bench/README.md` with the new run labeled with its judge model.
- [x] S8. README overhaul: route count, Roadmap prune, spec-conformance wording, version-neutral model wording, reflect the Haiku test results.
- [x] S9. Version bump + CHANGELOG. Re-check repo description and topics. Full test run and final read-through.

## Progress log

- 2026-07-23: Audit complete, findings 1 to 9 above. Plan committed (S1).
- 2026-07-23: S2 done. `aggregate_pilot.py` reads `bench/scores/*.json` directly (any arms present in the file); recomputed values for the two vendored arms reproduce the README table exactly. `tests/check_skill.sh` now recomputes every vendored arm and fails if the README table row drifts.
- 2026-07-23: S3 done. `bench/README.md` now states which rows are recomputable from vendored scores and which two are a recorded result only, with re-verification pointed at this plan.
- 2026-07-23: S4 done. Run A results in `tests/e2e/README.md`: setup perfect, web search from the small agent works, but triage punted the ambiguous question back to the user, no investigation phases ran, and Storage never happened (no entry, no index row). Three skill fixes queued for S6. Run B (S5) moved after S6 so the stop rule is tested on the patched skill.
- 2026-07-23: S6 done. Ambiguous-question rule, no-subagent inline fallback, and a fourth core rule (Investigation always ends in Storage) added to all four skill copies; `check_skill.sh` asserts the new lines. Re-run A2 on the patched skill passed the whole pipeline cold, including a populated contrarian section.
- 2026-07-23: S5 done. Warm-store run B answered from the stored Summary in 5 tool calls with zero web searches and never opened the full entry. Cold run C on the second dummy prompt in flight.
- 2026-07-23: S7 done. Fresh 2-arm run on DRB2 tasks 62/114/80: Haiku writers with live web research, Haiku judges on all 126 rubric items with the blocked-source rule, judge reasoning spot-checked across four cells. Skill brief beats baseline on weighted score (44.3% vs 36.2%); the gap is concentrated in analysis attribution (task 114: baseline 6 of 8 blocked, skill 1). Task 62 recall collapsed for both arms, which the Opus-written run had solved, giving the Opus-class recommendation a measured basis. Reports and scores vendored under `bench/`; drift test covers both tables.
- 2026-07-23: S8 done. README: 4-route count everywhere, roadmap cut from 56 lines to 5, spec section names the extension fields, model wording version-neutral, small-model and bench bullets point at `tests/e2e/` and the vendored run. Run C logged (second cold topic appended cleanly; one cosmetic wrong-path line in the chat answer while disk state was correct).
- 2026-07-23: S9 done. v0.3.6 released: CHANGELOG entry, all three manifests and the README badge bumped, full test suite passing, GitHub description updated to name the small-model end-to-end testing. Plan complete.

## Phase 2: local-host benchmark under noob-cli (2026-07-23)

Goal: run the skill end to end under noob-cli 0.5.0 with its bundled websearch-skill 0.2.3, against a local llama.cpp endpoint (llama-vulkan-strix stack, Qwen3.6-35B-A3B Q4_K_M), with real web searches, and record the measurements in this repo. The host matrix then covers three tiers: Fable-class (development), Haiku-class (bench run 2), and a local 35B MoE through a third-party CLI.

- [x] P1. Verify the stack: noob-cli 0.5.0 (Cargo.toml, binary), websearch-skill 0.2.3 (dist-info inside the runtime image), llama.cpp build b10103 serving Qwen3.6-35B-A3B Q4_K_M with 5 slots of 131,072 ctx (llama-vulkan-strix compose).
- [x] P2. Benchmark suite in a sandbox workspace with the skill installed at `.claude/skills/research/` (noob discovers that root natively): run 1 cold store, run 2 warm store (stop rule), run 3 second cold topic. Headless `noob exec -p ... --json --yolo`, wall-clock timed, transcript-graded (tool calls, real websearch invocations), disk-graded (same checks as the e2e harness).
- [x] P3. Write results into `tests/e2e/README.md` as a host-matrix section naming the exact versions; commit.

Progress:
- 2026-07-23: P1 done. Versions verified from the artifacts, not the docs. Side task landed in the llama-vulkan-strix repo (its own commits): the stack is single-service again, laguna default, qwen the documented swap.
- 2026-07-23: P2 run 1 done, 287 s wall, and it produced the phase's first fix. The host indexes skills as one clipped 200-char description line; ours opened with store mechanics and kept every trigger phrase in `when_to_use`, a field spec-only hosts never read. The model researched (detached child, live 2026 data) but never loaded the skill, so nothing was stored. Description rewritten to lead with the trigger questions inside the 200-char window; re-running cold as run 2.
- 2026-07-23: P2 runs 2 and 3 done. Cold: 839 s, 11 tool calls, zero errors, full pipeline including the write verification; 48 sources; parent emitted ~3,900 tokens total with 60% being the findings write. Warm: 33 s, zero searches, answered from the store; 25x faster than cold on the identical question. Full trace in `tests/e2e/README.md`.
- 2026-07-23: P2 runs 4 and 4b: the second dummy prompt ("best coding language for 3d games today") missed activation twice; the model loaded the generic web-search skill instead and nothing was stored. Prompt-dependent, not random: the fps prompt activates 2/2, this one 0/2. Description now names the tie-break against plain web-search skills inside the 200-char clip; run 4c measures it.
- 2026-07-23: Depth triage shipped (quick vs deep) after the 839 s cold run made the single-gear cost visible: narrow questions or a "quick" signal get 3-6 searches and minutes, comparisons keep the full walk, quick entries carry `depth: quick` and upgrade by deep merge. All four copies plus test assertions.
- 2026-07-23: P2/P3 closed, v0.4.0 released. Final numbers: deep cold 839 s (48 sources, zero errors), warm 33 s, quick 29-42 s, explicit invocation 1/1 vs model-initiated 2/5. Quick keeps the full mini-pipeline by spec (contrarian step and write-before-answer are numbered order steps); the 35B holds it for gathering but not persistence, and speed-worded prompts suppress voluntary activation even on Haiku. All traces in `tests/e2e/README.md`. llama-vulkan-strix `.env` restored to laguna default. GitHub description names the depths and the local-host testing.
- 2026-07-23: v0.4.1. The inline-quick allowance was the wrong call: quick must store and run the contrarian, so it now keeps deep's spawn-return-store skeleton with a 3-6 search brief. Re-measured on the same 35B stack: 444 s, entry with `depth: quick`, worked contrarian objection, verified write, zero errors. The depths differ in effort only.
