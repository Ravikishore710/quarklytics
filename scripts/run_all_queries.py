"""Run and validate all 42 analytical queries and save selected bounded results."""
from __future__ import annotations
import os, re, csv
from pathlib import Path
import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]

def conninfo():
    return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"

def parse_queries():
    files = sorted((ROOT / 'sql/04_analytics').glob('0*.sql'))
    queries = []
    for f in files:
        if f.name.startswith('00_') or f.name.startswith('01_build') or f.name.startswith('02_build'):
            continue
        text = f.read_text(encoding='utf-8')
        blocks = re.split(r'(?=--\s*query_id:)', text)
        for b in blocks:
            b = b.strip()
            if not b.startswith('-- query_id:'):
                continue
            qid_m = re.search(r'--\s*query_id:\s*(Q\d+)', b)
            if not qid_m:
                continue
            qid = qid_m.group(1)
            lines = b.splitlines()
            sql_lines = [l for l in lines if not l.strip().startswith('--')]
            sql = '\n'.join(sql_lines).strip()
            queries.append((qid, sql, f.name))
    return queries

def main():
    load_dotenv()
    queries = parse_queries()
    print(f"Discovered {len(queries)} analytical queries.")
    selected_out = ROOT / 'evaluation/results/selected_results'
    selected_out.mkdir(parents=True, exist_ok=True)
    
    SAMPLE_EXPORT_QIDS = {'Q01', 'Q02', 'Q04', 'Q05', 'Q08', 'Q12', 'Q15', 'Q19', 'Q24', 'Q28', 'Q32', 'Q33', 'Q35', 'Q38', 'Q41', 'Q42'}
    
    with psycopg.connect(conninfo()) as conn:
        with conn.cursor() as cur:
            for qid, sql, fname in queries:
                try:
                    cur.execute(sql)
                    cols = [d[0] for d in cur.description]
                    rows = cur.fetchall()
                    print(f"[OK] {qid} ({fname}): {len(rows)} rows returned")
                    
                    if qid in SAMPLE_EXPORT_QIDS:
                        bounded_rows = rows[:25]
                        csv_path = selected_out / f"{qid}_result.csv"
                        with csv_path.open('w', newline='', encoding='utf-8') as cf:
                            writer = csv.writer(cf)
                            writer.writerow(cols)
                            writer.writerows(bounded_rows)
                        print(f"  -> Exported top {len(bounded_rows)} rows to {csv_path.name}")
                except Exception as e:
                    print(f"[FAIL] {qid} ({fname}): {e}")
                    raise

    print("\nAll 42 analytical queries executed successfully!")

if __name__ == '__main__':
    main()
