"""Reproducible local pipeline; Python orchestrates, SQL performs transformations."""
from __future__ import annotations
import argparse, os, subprocess, sys
from pathlib import Path
import psycopg
from dotenv import load_dotenv
ROOT=Path(__file__).resolve().parents[1]
def conninfo(): return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"
def execute(rel):
    sql=(ROOT/rel).read_text(encoding='utf-8')
    with psycopg.connect(conninfo()) as c:
        with c.cursor() as cur:
            cur.execute(sql)
            if cur.description:
                rows = cur.fetchall()
                cols = [desc[0] for desc in cur.description]
                print(f'--- {rel} ({len(rows)} rows) ---')
                print(' | '.join(cols))
                for row in rows:
                    print(' | '.join(str(v) for v in row))
        c.commit()
    print(f'ran {rel}')
def main():
    load_dotenv(); ap=argparse.ArgumentParser(); g=ap.add_mutually_exclusive_group(required=True); g.add_argument('--sample',action='store_true'); g.add_argument('--full',action='store_true'); a=ap.parse_args()
    execute('sql/00_database/01_create_schemas.sql'); execute('sql/01_raw/01_create_tables.sql')
    subprocess.run([sys.executable,'scripts/database/load_raw.py'] + (['--sample'] if a.sample else []),cwd=ROOT,check=True)
    for rel in ['sql/02_core/01_create_tables.sql','sql/02_core/03_transform.sql','sql/02_core/02_constraints.sql','sql/03_validation/01_row_counts.sql','sql/03_validation/02_integrity.sql','sql/03_validation/03_null_profile.sql','sql/03_validation/04_domain_checks.sql','sql/04_analytics/00_create_tables.sql','sql/04_analytics/01_build_dimensions.sql','sql/04_analytics/02_build_facts.sql','sql/05_views/01_views.sql','sql/05_views/02_materialized_views.sql','sql/06_indexes/01_baseline.sql']:
        execute(rel)
    print('Pipeline complete. Run SQL tests and benchmarks separately.')
if __name__=='__main__': main()
