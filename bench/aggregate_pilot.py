#!/usr/bin/env python3
"""Aggregate the Sonnet-judged pilot scores into a per-arm comparison."""
import json, os, sys

BASE = os.path.dirname(os.path.abspath(__file__))
DIMS = ['info_recall', 'analysis', 'presentation']
TASKS = [62, 114, 80]
ARMS = ['research-skill', 'baseline']
# DRB2 weights content over presentation; the paper does not publish exact weights,
# so this uses an explicit, stated weighting rather than an implied official one.
WEIGHTS = {'info_recall': 0.5, 'analysis': 0.35, 'presentation': 0.15}


def load(arm, idx):
    p = os.path.join(BASE, 'judge', arm, f'scored-{idx}.json')
    if not os.path.exists(p):
        return None
    return json.load(open(p))


def rubric_counts(idx):
    tasks = {json.loads(l)['idx']: json.loads(l)
             for l in open(os.path.join(BASE, 'tasks_and_rubrics.jsonl'))}
    r = tasks[idx]['content']['rubric']
    return {d: len(r[d]) for d in DIMS}


def main():
    rows = {}
    missing = []
    for arm in ARMS:
        for idx in TASKS:
            data = load(arm, idx)
            if data is None:
                missing.append(f'{arm}/{idx}')
                continue
            expect = rubric_counts(idx)
            per = {}
            for d in DIMS:
                items = data.get(d, [])
                scores = [it['score'] for it in items]
                n = expect[d]
                per[d] = dict(
                    n=n,
                    graded=len(scores),
                    hit=sum(1 for s in scores if s == 1),
                    miss=sum(1 for s in scores if s == 0),
                    blocked=sum(1 for s in scores if s == -1),
                )
                per[d]['rate'] = 100.0 * per[d]['hit'] / n if n else 0.0
            rows[(arm, idx)] = per

    if missing:
        print('missing scored files:', ', '.join(missing))
    if not rows:
        sys.exit(1)

    print(f"{'arm':16}{'task':>5} | " + " | ".join(f"{d:>24}" for d in DIMS))
    for idx in TASKS:
        for arm in ARMS:
            per = rows.get((arm, idx))
            if not per:
                continue
            cells = []
            for d in DIMS:
                p = per[d]
                flag = '' if p['graded'] == p['n'] else f"!{p['graded']}"
                cells.append(f"{p['hit']:>2}/{p['n']:<2} {p['rate']:5.1f}% blk={p['blocked']:<2}{flag}")
            print(f"{arm:16}{idx:>5} | " + " | ".join(f"{c:>24}" for c in cells))
        print()

    print('Per-arm means across graded tasks:')
    for arm in ARMS:
        got = [(i, rows[(arm, i)]) for i in TASKS if (arm, i) in rows]
        if not got:
            continue
        means = {}
        tot_hit = tot_n = tot_blk = 0
        for _, per in got:
            for d in DIMS:
                means.setdefault(d, []).append(per[d]['rate'])
                tot_hit += per[d]['hit']
                tot_n += per[d]['n']
                tot_blk += per[d]['blocked']
        m = {d: sum(v) / len(v) for d, v in means.items()}
        weighted = sum(m[d] * WEIGHTS[d] for d in DIMS)
        print(f"  {arm:15} n_tasks={len(got)}  recall {m['info_recall']:5.1f}%  "
              f"analysis {m['analysis']:5.1f}%  presentation {m['presentation']:5.1f}%  "
              f"| weighted {weighted:5.1f}%  all-rubric {100.0*tot_hit/tot_n:5.1f}%  blocked {tot_blk}")


if __name__ == '__main__':
    main()
