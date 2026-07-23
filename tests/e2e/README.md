# End-to-end dummy tests (small-model harness)

Manual harness for checking that the skill survives a low-capability host agent with minimal briefing. The point is deliberate under-instruction: a weak model, an ambiguous prompt, and nothing else. If the skill only works when the operator adds guidance, it does not work.

## Protocol

1. Create a throwaway git repo (sandbox) with a copy of `SKILL.md` in it.
2. Spawn the smallest available agent tier (Haiku class) with only this wrapper:
   "You are a coding agent. Your current project is `<sandbox>` (a git repo). The skill file `RESEARCH-SKILL.md` in the project root is active for this conversation: read it and follow it. User message: `<dummy prompt>`"
3. Use ambiguous consumer-grade dummy prompts, for example "find me the best fps game" or "whats the best coding language for 3d games today". Do not clarify, do not add instructions. If the agent asks a question back, reply once with "idk just find the best one for me, updated" and nothing more.
4. After the run, inspect the sandbox, not the chat: `.research/INDEX.md` row present, `<slug>/FINDINGS.md` exists with all schema sections, `.gitignore` contains `.research/`, sources carry fetch dates from the actual current year (proves live web use, not model priors).

Pass requires the disk state, not a good-sounding chat answer.

## Run log

### 2026-07-23, run A, cold store, prompt "find me the best fps game" (skill v0.3.5, Haiku)

- Setup: PASS. Exact `INDEX.md` template, `.gitignore` entry, correct location on first activation.
- Triage: FAIL. Classified the question as "when NOT to use", answered casually from training priors with zero searches, and asked the user which approach they preferred instead of proceeding.
- After the one allowed nudge: used year-pinned web search (2026 sources) and gave a sourced answer. Web access from the small agent confirmed working.
- Investigation: FAIL. No subagent spawn attempted, no inline phase walk, no contrarian pass.
- Storage: FAIL. No `FINDINGS.md`, no index row, no write verification. The data layer received nothing; the whole persistent-store purpose of the skill was skipped.

Diagnosis: v0.3.5 gave a small model two outs, and it took both. Nothing legitimized inline investigation when it could not or did not spawn a subagent, and nothing said an ambiguous "best X" question is a comparison to research rather than a casual lookup to wave at. Fixed in v0.3.6: ambiguous-question rule in triage, inline fallback for hosts without subagents, and Storage promoted into the core rules (research that never reaches `.research/` is a failed run).

### 2026-07-23, run A2, cold store, same prompt (skill v0.3.6, Haiku, fresh sandbox)

- Full pipeline unprompted: no question back to the user, no priors-only answer. 28 tool calls, 15+ sources all fetched 2026-07-23.
- Storage: PASS. `best-fps-games-2026/FINDINGS.md` with all 7 schema sections and correct frontmatter, INDEX.md row with a specific one-liner, `.gitignore` correct.
- Contrarian pass produced real content (hacker problems, paywall cosmetics, balance complaints) instead of "none found".
- Chat answer stayed brief and pointed at the stored path, as the skill specifies.

The three v0.3.6 rules account for the difference; the model and prompt were identical to run A.

### 2026-07-23, run B, warm store, same prompt re-asked by a fresh agent (skill v0.3.6, Haiku)

- Retrieval-only, 5 tool calls, 22 seconds: read the skill, resolved the project root, read `INDEX.md`, `sed`-extracted the matched entry's `## Summary`, answered from it, stopped.
- Zero web searches, and the full `FINDINGS.md` body was never opened. The tier-2 stop rule holds on the smallest model tier.

### 2026-07-23, run C, cold store, prompt "whats the best coding language for 3d games today" (skill v0.3.6, Haiku, same sandbox)

- Full pipeline unprompted: 28 tool calls, 9 sources fetched same-day, entry stored with all 7 schema sections and a comparison across C++, C#, GDScript, and Rust.
- INDEX.md row appended correctly next to the existing entry; nothing clobbered.
- One cosmetic slip: the final chat message cited a wrong absolute path for the entry while the actual write, and the skill's write verification, used the correct project. Disk state is what the harness grades, and it passed.

## Host matrix: noob-cli with a local 35B model

Deliberate stress test on the smallest practical stack: a third-party SKILL.md host driving a local quantized MoE model, headless, stock configuration, ambiguous dummy prompts. Versions, all verified from the running artifacts rather than the docs: noob-cli 0.5.0 (Rust binary, Docker host-network launcher, `noob exec -p ... --json --yolo`), websearch-skill 0.2.3 (dist-info inside the runtime image; bundled CLI plus stdio MCP server, keyless), Qwen3.6-35B-A3B Q4_K_M served by llama.cpp build b10103-c588c4f47 (Vulkan backend, llama-vulkan-strix stack, 5 slots of 131,072 ctx). The skill sat at `.claude/skills/research/SKILL.md` in a throwaway git workspace, one of the four roots noob discovers natively.

### 2026-07-23, noob run 1, cold, "find me the best fps game": activation miss, description fixed

The parent researched (one `task` spawn, a detached child that returned live 2026 data) but never loaded the skill: no setup, no storage, nothing on disk after 287 s. Cause, from the host source: noob's resolver index presents each skill as one line, `name: description`, with the description clipped to 200 characters. The description then led with store mechanics, and every trigger phrase lived in `when_to_use`, a Claude Code extension field that spec-only hosts do not read. The description now leads with the trigger questions inside the first 200 characters. The agentskills spec itself asks for triggers in `description`; the old text had them in the wrong field.

### 2026-07-23, noob run 2, cold, same prompt, fixed description: full pipeline, zero errors

839 s wall, 11 tool calls, every result flag clean, no retries: skill load, `date`, project root, store check, `mkdir`, INDEX.md written with the exact template, one detached child spawned with the skill's zero-context brief (date pinned, effort scaling "15-25 searches", contrarian pass), FINDINGS.md written, index row appended, and the skill's write verification executed as the final call. The stored entry has all 7 schema sections, 48 sources (Steam charts, Metacritic, esports viewership reports, patch notes, 2026-dated coverage), causal insights with figures, and a populated contrarian objection. Multi-agent verified at the process level: `noob` (parent, pid 1) spawned `noob` (child) which owned the `websearch` MCP server process; one server instance for the whole run, and a direct `websearch web-search` invocation in the same container returned `ok: true` on contract 1.1.0.

Context economy, measured from the event stream: the parent emitted roughly 3,900 tokens across the whole run. 60% of that is the single unavoidable cost, re-emitting the child's findings into the `write` call; the child's brief is ~770 tokens, the user-facing answer ~560, and setup plus index edit plus verification ~220 together. Search mechanics, format rules, and the contrarian pass reached only the child; the parent never saw a raw search result, and the 48 sources' fetch traffic died with the child's context. Parent final context: 18,601 prompt tokens, 18,582 of them KV-cache hits. That split is the design: the main agent reads the index, spawns, stores, and stays out of the research; the single-writer rule is what keeps concurrent children from ever contending for `.research/`.

Deviations logged: the `.gitignore` setup step was skipped; frontmatter drifted from the schema (no `topic` key, bare source URLs without fetch dates, `raw: []` present instead of omitted); the index row wrapped the path in backticks. The store remains fully functional for retrieval; all three are small-model formatting drift, not pipeline failures.

### 2026-07-23, noob run 3, warm, same prompt: 33 s, store answers, no web

Fresh process, same workspace: 7 tool calls, zero errors, no child, zero searches. The parent loaded the skill, read the index, matched the entry, and answered from the store. 33 s against run 2's 839 s is the persistence payoff on a repeated question, measured at 25x on identical hardware. Two discipline notes: it also loaded the bundled web-search skill it then never used, and it read the full FINDINGS.md body instead of sed-extracting `## Summary`, paying roughly 2,300 prompt tokens where the stop rule budgets ~200. The answer was correct either way; the stop rule's value shows up as exactly that token delta.

### 2026-07-23, noob runs 4 to 4d: activation is prompt-dependent, explicit invocation is total

The second dummy prompt, "whats the best coding language for 3d games today", never activated the skill on its own: three cold attempts across three description versions all went to an ad-hoc research child (once via the generic web-search skill, once with no skill at all), left nothing on disk, and one hedged its answer to "2025-2026" without the skill's date pinning. The fps prompt activates 2 of 2 with the same descriptions. The model plainly believes it already knows how to research programming topics and routes around the skill; description engineering moved the first prompt from miss to hit and did nothing for the second. The control run, "use the research skill: whats the best coding language for 3d games today", executed the entire pipeline in 10 calls with zero errors: second entry stored beside the first, index appended without touching the existing row, write verified, 547 s. Measured activation on this host and model: model-initiated 2 of 5 on ambiguous prompts, explicit invocation 1 of 1. The practical guidance for small hosts is the same one Claude Code gets with `/research`: name the skill when the answer should persist.

### 2026-07-23, Haiku quick-prompt probe: speed words suppress voluntary activation

Two Haiku runs with "quick: whats the latest stable rust/go version" under the dummy wrapper (skill file present, reading it voluntary): both skipped the skill read entirely, did one web search, answered, stored nothing. One even answered a version its own cited source contradicted. The same Haiku setup activates 3 of 3 on prompts without a speed word. A speed-signaled prompt primes the agent to bypass procedure before the skill's own quick path can catch it; hosts that inject the skill body automatically (Claude Code activation) or an explicit invocation are immune, which is where the quick order below applies.

### 2026-07-23, noob runs 5 to 5c: quick depth is 29-42 s; persistence has a model floor

Quick runs on fresh narrow topics (latest stable Python, Node, Rust versions, each invoked with "use the research skill, quick:"). All three: skill loaded, 3 to 5 fetches against primary sources (python.org, endoflife.date, nodejs.org dist index, rust-lang.org, one run through the websearch MCP), correct current answers, 29 to 42 s wall. That is the lightweight path working: ~29x faster than a deep cold run, comparable to a warm retrieval. Two runs hit transient fetch errors (`err: true`) and recovered unprompted on the next call, the only errors in the entire suite. None of the three stored an entry, across three strengthenings of the storage instruction ending in the write-before-answer order. On this 35B the inline quick path reaches "answered" and stops, every time; the deep path stores every time because the child-return step structurally leads into Storage. Persistence on quick is a model-capability floor on this stack, not a missing rule, and the write-before-answer order stays in the skill for the tiers that do follow it.
