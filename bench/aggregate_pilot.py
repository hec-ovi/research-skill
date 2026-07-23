#!/usr/bin/env python3
"""Recompute the pilot comparison from the vendored per-rubric scores.

Usage:
    python3 bench/aggregate_pilot.py [scores-file ...]

With no arguments, every JSON file under bench/scores/ is aggregated.
Each file maps "<arm>/<task>" to per-dimension score arrays, where each
item is 1 (rubric satisfied), 0 (absent), or -1 (satisfied but attributed
to the task's blocked source). Array lengths are the rubric counts.
"""
import glob
import json
import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
DIMS = ['info_recall', 'analysis', 'presentation']
# DRB2 weights content over presentation; the paper does not publish exact
# weights, so this uses an explicit, stated weighting rather than an implied
# official one.
WEIGHTS = {'info_recall': 0.5, 'analysis': 0.35, 'presentation': 0.15}


def aggregate(path):
    with open(path) as f:
        data = json.load(f)

    cells = {}   # (arm, task) -> {dim: {n, hit, miss, blocked, rate}}
    arms = []
    tasks = []
    for key, dims in data.items():
        arm, task = key.rsplit('/', 1)
        if arm not in arms:
            arms.append(arm)
        if task not in tasks:
            tasks.append(task)
        per = {}
        for d in DIMS:
            scores = dims.get(d, [])
            n = len(scores)
            per[d] = dict(
                n=n,
                hit=sum(1 for s in scores if s == 1),
                miss=sum(1 for s in scores if s == 0),
                blocked=sum(1 for s in scores if s == -1),
            )
            per[d]['rate'] = 100.0 * per[d]['hit'] / n if n else 0.0
        cells[(arm, task)] = per

    print(f'== {os.path.relpath(path, BASE)}')
    print(f"{'arm':24}{'task':>5} | " + " | ".join(f"{d:>20}" for d in DIMS))
    for task in tasks:
        for arm in arms:
            per = cells.get((arm, task))
            if not per:
                continue
            row = []
            for d in DIMS:
                p = per[d]
                row.append(f"{p['hit']:>2}/{p['n']:<2} {p['rate']:5.1f}% blk={p['blocked']:<2}")
            print(f"{arm:24}{task:>5} | " + " | ".join(f"{c:>20}" for c in row))
        print()

    summary = {}
    print('Per-arm means across tasks:')
    for arm in arms:
        got = [cells[(arm, t)] for t in tasks if (arm, t) in cells]
        means = {d: sum(per[d]['rate'] for per in got) / len(got) for d in DIMS}
        blocked = sum(per[d]['blocked'] for per in got for d in DIMS)
        weighted = sum(means[d] * WEIGHTS[d] for d in DIMS)
        summary[arm] = dict(
            info_recall=round(means['info_recall'], 1),
            analysis=round(means['analysis'], 1),
            presentation=round(means['presentation'], 1),
            weighted=round(weighted, 1),
            blocked=blocked,
        )
        print(f"  {arm:22} n_tasks={len(got)}  recall {means['info_recall']:5.1f}%  "
              f"analysis {means['analysis']:5.1f}%  presentation {means['presentation']:5.1f}%  "
              f"| weighted {weighted:5.1f}%  blocked {blocked}")
    print()
    return summary


def main():
    paths = sys.argv[1:] or sorted(glob.glob(os.path.join(BASE, 'scores', '*.json')))
    if not paths:
        print('no score files found', file=sys.stderr)
        sys.exit(1)
    out = {}
    for p in paths:
        out[os.path.basename(p)] = aggregate(p)
    return out


if __name__ == '__main__':
    main()
