"""Summarize measured query benchmark results across variants."""
from __future__ import annotations
import csv, statistics
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def main():
    data = defaultdict(lambda: defaultdict(list))
    csv_path = ROOT / 'evaluation/query_benchmarks.csv'
    with csv_path.open('r', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            qid = row['query_id']
            var = row['variant']
            exec_ms = float(row['execution_ms'])
            plan_ms = float(row['planning_ms'])
            hit = int(row['shared_hit_blocks'])
            read = int(row['shared_read_blocks'])
            idx = row['index_used']
            data[qid][var].append((exec_ms, plan_ms, hit, read, idx))

    header = f"{'Query':<8} | {'Variant':<14} | {'Median Exec ms':<16} | {'Mean Plan ms':<15} | {'Shared Hit':<10} | {'Shared Read':<11} | {'Index Used':<10}"
    print(header)
    print('-' * len(header))
    for qid in sorted(data.keys()):
        for var in ['baseline', 'optimized', 'materialized']:
            if var in data[qid]:
                runs = data[qid][var]
                med_exec = statistics.median([r[0] for r in runs])
                mean_plan = statistics.mean([r[1] for r in runs])
                med_hit = statistics.median([r[2] for r in runs])
                med_read = statistics.median([r[3] for r in runs])
                idx_used = runs[0][4]
                print(f"{qid:<8} | {var:<14} | {med_exec:<16.3f} | {mean_plan:<15.3f} | {med_hit:<10} | {med_read:<11} | {idx_used:<10}")

if __name__ == '__main__':
    main()
