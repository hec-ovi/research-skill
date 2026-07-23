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
