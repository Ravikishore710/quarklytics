"""Helper CLI to execute ad-hoc SQL or specific benchmark/analytical queries."""
from __future__ import annotations
import argparse, os, re
from pathlib import Path
import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]

def conninfo():
    return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"

def find_query(qid: str) -> str | None:
    for path in sorted((ROOT / 'sql/04_analytics').glob('0*.sql')):
        text = path.read_text(encoding='utf-8')
        blocks = re.split(r'(?=--\s*query_id:)', text)
        for b in blocks:
            if re.search(rf'--\s*query_id:\s*{qid}\b', b, re.IGNORECASE):
                lines = [l for l in b.splitlines() if not l.strip().startswith('--')]
                return '\n'.join(lines).strip()
    return None

def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Test and execute SQL queries on Quarklytics database.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c', '--command', help="Raw SQL query string to run.")
    group.add_argument('-q', '--query-id', help="Analytical query ID (e.g. Q01, Q05, Q24, Q35).")
    parser.add_argument('-l', '--limit', type=int, default=20, help="Row limit for output display (default: 20).")
    args = parser.parse_args()

    sql = args.command
    if args.query_id:
        sql = find_query(args.query_id.upper())
        if not sql:
            raise SystemExit(f"Query {args.query_id} not found in sql/04_analytics/")
        print(f"--- Executing {args.query_id.upper()} ---")

    with psycopg.connect(conninfo()) as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            if cur.description:
                cols = [desc[0] for desc in cur.description]
                rows = cur.fetchall()
                print(f"Returned {len(rows)} rows (showing top {min(len(rows), args.limit)}):")
                print(" | ".join(cols))
                print("-" * max(40, len(" | ".join(cols))))
                for r in rows[:args.limit]:
                    print(" | ".join(str(v) for v in r))
            else:
                conn.commit()
                print("Query executed successfully (no rows returned).")

if __name__ == '__main__':
    main()
