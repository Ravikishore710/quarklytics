"""Run JSON EXPLAIN ANALYZE plans and serialize measured evidence."""
from __future__ import annotations
import argparse,csv,json,os,statistics,time
from pathlib import Path
import psycopg
from dotenv import load_dotenv
ROOT=Path(__file__).resolve().parents[2]
def conninfo(): return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"
def flatten(plan):
    p=plan[0]['Plan']; return {'execution_ms':plan[0].get('Execution Time'),'planning_ms':plan[0].get('Planning Time'),'rows':p.get('Actual Rows'),'shared_hit_blocks':p.get('Shared Hit Blocks',0),'shared_read_blocks':p.get('Shared Read Blocks',0),'temp_read_blocks':p.get('Temp Read Blocks',0),'index_used':'Index' in p.get('Node Type','') or 'Index' in json.dumps(p)}
def main():
    load_dotenv(); ap=argparse.ArgumentParser(); ap.add_argument('--runs',type=int,default=3); ap.add_argument('--variant',choices=['baseline','optimized','materialized','current'],default='current'); ap.add_argument('--cold-cache-notes',default=''); a=ap.parse_args()
    out=ROOT/'evaluation/results/selected_results'; out.mkdir(parents=True,exist_ok=True); rows=[]
    MATERIALIZED_SQL = {
        'Q24': "SELECT month_key, sum(total_revenue) revenue FROM analytics.mv_monthly_category_revenue GROUP BY 1 ORDER BY 1;",
        'Q35': "SELECT category, sum(total_revenue) revenue FROM analytics.mv_monthly_category_revenue WHERE category IS NOT NULL GROUP BY 1 ORDER BY revenue DESC;"
    }
    with psycopg.connect(conninfo()) as c:
        for path in sorted((ROOT/'sql/07_benchmarks').glob('Q*.sql')):
            qid=path.stem
            if a.variant == 'materialized':
                if qid not in MATERIALIZED_SQL:
                    continue
                sql = MATERIALIZED_SQL[qid]
            else:
                sql=path.read_text(encoding='utf-8')
            variant=a.variant
            for run in range(1,a.runs+1):
                with c.cursor() as cur:
                    cur.execute('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) '+sql)
                    plan=cur.fetchone()[0]; metrics=flatten(plan); metrics.update(query_id=qid,variant=variant,run=run,notes=a.cold_cache_notes)
                    rows.append(metrics)
            (out/f'{qid}_{variant}.json').write_text(json.dumps(plan,indent=2,default=str))
    
    csv_file = ROOT/'evaluation/query_benchmarks.csv'
    fields=['query_id','variant','execution_ms','planning_ms','shared_hit_blocks','shared_read_blocks','temp_read_blocks','rows','index_used','notes']
    existing_rows = []
    if csv_file.exists():
        with csv_file.open('r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            if reader.fieldnames:
                existing_rows = [r for r in reader if r.get('variant') != a.variant]
    all_rows = existing_rows + [{k:r.get(k) for k in fields} for r in rows]
    with csv_file.open('w', newline='', encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(all_rows)
    print(f'Wrote {len(rows)} benchmark observations ({len(all_rows)} total in CSV).')
if __name__=='__main__': main()
