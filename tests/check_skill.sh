#!/usr/bin/env bash
# Local consistency checks for the skill files. Run: bash tests/check_skill.sh
set -u
cd "$(dirname "$0")/.."

fail=0
err() { echo "FAIL: $1"; fail=1; }
ok() { echo "ok: $1"; }

ROOT_SKILL=SKILL.md
COPIES=(skills/research/SKILL.md plugins/research/skills/research/SKILL.md)
CODEX=plugins/research-codex/skills/research/SKILL.md
ALL=("$ROOT_SKILL" "${COPIES[@]}" "$CODEX")

# 1. The three Claude copies are byte-identical
for f in "${COPIES[@]}"; do
  if cmp -s "$ROOT_SKILL" "$f"; then ok "$f identical to root SKILL.md"; else err "$f differs from root SKILL.md"; fi
done

# 2. Required sections present in all four skill files
SECTIONS=(
  "## Setup (first use only)"
  "### 1. Retrieval"
  "### 2. Investigation"
  "### 3. Storage"
  "#### Review before storing"
  "## File schemas"
  "## Anti-patterns"
  "**Insight extraction**"
  "## Insights"
  "## Strongest objection"
  "### Depth over polish"
)
for f in "${ALL[@]}"; do
  for s in "${SECTIONS[@]}"; do
    grep -qF "$s" "$f" || err "$f missing: $s"
  done
done
ok "section scan done"

# 3. Frontmatter sanity: name + description in every skill file
for f in "${ALL[@]}"; do
  head -8 "$f" | grep -q '^name: research$' || err "$f frontmatter missing 'name: research'"
  head -8 "$f" | grep -q '^description: ' || err "$f frontmatter missing description"
done
ok "frontmatter scan done"

# 4. No em/en dashes in docs
for f in "${ALL[@]}" README.md CHANGELOG.md bench/README.md docs/PLAN.md tests/e2e/README.md; do
  if grep -qP '[\x{2013}\x{2014}]' "$f"; then err "$f contains em/en dash"; fi
done
ok "dash scan done"

# 5. Version consistency: plugin.json files, marketplace.json, README badge, CHANGELOG latest release
v_plugin=$(grep -o '"version": "[^"]*"' plugins/research/.claude-plugin/plugin.json | head -1 | cut -d'"' -f4)
v_codex=$(grep -o '"version": "[^"]*"' plugins/research-codex/.codex-plugin/plugin.json | head -1 | cut -d'"' -f4)
v_market=$(grep -o '"version": "[^"]*"' .claude-plugin/marketplace.json | head -1 | cut -d'"' -f4)
v_readme=$(grep -o 'Version-[0-9.]*-blue' README.md | head -1 | sed 's/Version-//;s/-blue//')
v_changelog=$(grep -o '^## \[[0-9.]*\]' CHANGELOG.md | head -1 | tr -d '#[] ')
for pair in "codex-plugin:$v_codex" "marketplace:$v_market" "readme-badge:$v_readme" "changelog:$v_changelog"; do
  name=${pair%%:*}; val=${pair#*:}
  [ "$val" = "$v_plugin" ] || err "version mismatch: $name=$val vs plugin.json=$v_plugin"
done
ok "version scan done (all $v_plugin)"

# 5b. Source-independence rules survive edits in every copy (earned on the DRB2 pilot)
for f in "${ALL[@]}"; do
  grep -qF 'the aggregator is a lead to follow, not the evidence' "$f" || err "$f lost the trace-to-primary rule"
  grep -qF 'is one source, not one per row' "$f" || err "$f lost the enumeration rule"
  grep -qF 'Open on the finding, not on the document that carried it' "$f" || err "$f lost the opening rule"
  grep -qF 'Credit the source the fact originates from' "$f" || err "$f lost the origin-attribution rule"
  grep -qF 'a list or table whose rows all trace to one document' "$f" || err "$f lost the single-source review tell"
done
ok "source-independence scan done"

# 5c. Small-model rules earned on the e2e dummy runs survive edits
for f in "${ALL[@]}"; do
  grep -qF 'Do not stall by asking the user which variant they meant' "$f" || err "$f lost the ambiguous-question rule"
  grep -qF 'Investigation always ends in Storage.' "$f" || err "$f lost the storage rule"
done
for f in "$ROOT_SKILL" "${COPIES[@]}"; do
  grep -qF 'run the same cognitive phases inline yourself' "$f" || err "$f lost the no-subagent inline fallback"
done
ok "small-model rule scan done"

# 5d. Depth triage (quick vs deep) survives edits in every copy
for f in "${ALL[@]}"; do
  grep -qF '**Also pick the depth:**' "$f" || err "$f lost the depth triage"
  grep -qF 'This is a quick lookup: 3-6 searches' "$f" || err "$f lost the quick effort line"
  grep -qF 'only then answer the user' "$f" || err "$f lost the quick write-before-answer order"
  grep -qF 'include one contrarian check' "$f" || err "$f lost the quick contrarian step"
  grep -qF 'never a bare lookup' "$f" || err "$f lost the quick-is-an-investigation rule"
  grep -qF 'depth: quick' "$f" || err "$f lost the quick frontmatter marker"
  grep -qF 'depth: deep' "$f" || err "$f lost the depth schema key"
done
ok "depth mode scan done"

# 5e. Output-contract and depth-promotion fixes (audit pass) survive edits in every copy
for f in "${ALL[@]}"; do
  grep -qF '## Supersedes' "$f" || err "$f lost the clean Supersedes header"
  grep -qF '## (Merge mode only) Supersedes' "$f" && err "$f still carries the parenthetical Supersedes header"
  grep -qF 'the quick entry is now promoted' "$f" || err "$f lost the merge-path depth promotion"
  grep -qF 'appears only in merge mode' "$f" || err "$f lost the merge-only Supersedes note"
done
ok "output-contract scan done"

# 6. Claude copies keep WebSearch/WebFetch wording; Codex copy must not use them
grep -q 'WebSearch' "$ROOT_SKILL" || err "root SKILL.md lost WebSearch wording"
grep -q 'WebSearch\|WebFetch' "$CODEX" && err "Codex SKILL.md contains Claude-specific tool names"

# 7. Bench tables match the vendored scores. Each row is bound to the run that
# owns it (bench/README.md rows anchor to their "## Run" section; the section is
# matched to a scores file by the filename its prose names), so swapping two runs'
# rows for a shared arm can no longer pass. The README.md headline table (run 3)
# is guarded too: its weighted cell is bold and its arm labels are shortened.
python3 - <<'EOF' || err "a bench table drifted from vendored scores (see output above)"
import glob, json, os, re, sys

DIMS = ['info_recall', 'analysis', 'presentation']
WEIGHTS = {'info_recall': 0.5, 'analysis': 0.35, 'presentation': 0.15}

def recompute(path):
    data = json.load(open(path))
    arms = {}
    for key, dims in data.items():
        arm, _task = key.rsplit('/', 1)
        arms.setdefault(arm, []).append(dims)
    out = {}
    for arm, tasks in arms.items():
        means = {d: sum(100.0 * sum(1 for s in t.get(d, []) if s == 1) / len(t[d]) for t in tasks) / len(tasks) for d in DIMS}
        blocked = sum(1 for t in tasks for d in DIMS for s in t.get(d, []) if s == -1)
        weighted = sum(means[d] * WEIGHTS[d] for d in DIMS)
        out[arm] = (round(means['info_recall'], 1), round(means['analysis'], 1),
                    round(means['presentation'], 1), round(weighted, 1), blocked)
    return out

SCORES = {os.path.basename(p): recompute(p) for p in sorted(glob.glob('bench/scores/*.json'))}
fail = False

# bench/README.md: rows anchored to their "## Run" section.
five = re.compile(r'^\| ([\w.-]+) \| ([\d.]+)% \| ([\d.]+)% \| ([\d.]+)% \| ([\d.]+)% \| (\d+) \|')
seven = re.compile(r'^\| ([\w.-]+) \| [\w. ]+ \| ([\d.]+)% \| ([\d.]+)% \| ([\d.]+)% \| ([\d.]+)% \| (\d+) \|')
section = None
sec_text = {}                     # heading -> lines
sec_rows = {}                     # (heading, arm) -> [tuples]
for ln in open('bench/README.md').read().splitlines():
    if ln.startswith('## '):
        section = ln.strip()
    sec_text.setdefault(section, []).append(ln)
    if section and section.startswith('## Run'):
        for rx in (five, seven):
            m = rx.match(ln)
            if m:
                sec_rows.setdefault((section, m.group(1)), []).append(
                    tuple(float(x) for x in m.groups()[1:5]) + (int(m.group(6)),))
for fname, arms in SCORES.items():
    owners = [h for h, txt in sec_text.items() if h and h.startswith('## Run') and fname in '\n'.join(txt)]
    if len(owners) != 1:
        print(f'bench/README.md: {fname} maps to {len(owners)} run sections {owners}, expected 1')
        fail = True
        continue
    for arm, want in arms.items():
        if want not in sec_rows.get((owners[0], arm), []):
            print(f'bench/README.md [{owners[0]}]: arm {arm} recomputes to {want}, rows: {sec_rows.get((owners[0], arm))}')
            fail = True

# README.md headline table: run 3, bold weighted cell, shortened arm labels.
readme = open('README.md').read()
run3 = SCORES.get('opus-2026-07-23.json', {})
label_map = {'research-skill': 'research-skill-haiku', 'baseline': 'baseline-haiku'}
readme_rows = {}
rx3 = re.compile(r'^\| ([^|]+?) \| [^|]+ \| ([\d.]+)% \| ([\d.]+)% \| ([\d.]+)% \| \*{0,2}([\d.]+)%\*{0,2} \| (\d+) \|', re.M)
for m in rx3.finditer(readme):
    arm = label_map.get(m.group(1).split('(')[0].strip())
    if arm:
        readme_rows.setdefault(arm, []).append(
            tuple(float(x) for x in m.groups()[1:5]) + (int(m.group(6)),))
for arm in ('research-skill-haiku', 'baseline-haiku'):
    want = run3.get(arm)
    if want and want not in readme_rows.get(arm, []):
        print(f'README.md headline table: arm {arm} recomputes to {want}, rows: {readme_rows.get(arm)}')
        fail = True

sys.exit(1 if fail else 0)
EOF
ok "bench tables match vendored scores (bench/README.md + README.md)"

# 8. Store schema invariants: INDEX dispatcher table + FINDINGS schema keys survive edits
for f in "${ALL[@]}"; do
  grep -qF '| Topic | Path | Last verified | One-liner |' "$f" || err "$f lost INDEX.md schema table"
  for key in 'topic: <slug>' 'last_verified: YYYY-MM-DD' '## Discarded approaches' '## Timeline' '## Open questions' 'status: active' 'related: \[\]'; do
    grep -q "$key" "$f" || err "$f lost FINDINGS schema element: $key"
  done
done
ok "store schema scan done"

if [ "$fail" = 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; exit 1; fi
