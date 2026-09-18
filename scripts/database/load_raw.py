"""Load local CSVs into source-fidelity raw tables using psycopg COPY."""
from __future__ import annotations
import argparse, os
from pathlib import Path
import psycopg
from dotenv import load_dotenv

TABLES={'olist_customers_dataset.csv':'customers','olist_orders_dataset.csv':'orders','olist_order_items_dataset.csv':'order_items','olist_order_payments_dataset.csv':'order_payments','olist_order_reviews_dataset.csv':'order_reviews','olist_products_dataset.csv':'products','olist_sellers_dataset.csv':'sellers','olist_geolocation_dataset.csv':'geolocation','product_category_name_translation.csv':'category_translation'}
def conninfo(): return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"
def main():
    load_dotenv(); ap=argparse.ArgumentParser(); ap.add_argument('--raw-dir',type=Path,default=Path('data/raw')); ap.add_argument('--sample',action='store_true'); a=ap.parse_args(); raw=a.raw_dir
    if a.sample: raw=Path('data/sample')
    missing=[n for n in TABLES if not (raw/n).exists()]
    if missing: raise SystemExit('Missing CSVs: '+', '.join(missing))
    with psycopg.connect(conninfo()) as conn:
        with conn.cursor() as cur:
            for filename,table in TABLES.items():
                cur.execute(f'TRUNCATE raw.{table}')
                with (raw/filename).open('r',encoding='utf-8-sig',newline='') as f:
                    with cur.copy(f'COPY raw.{table} FROM STDIN WITH (FORMAT csv, HEADER true, NULL \'\')') as copy:
                        while data:=f.read(1024*1024): copy.write(data)
                cur.execute(f'SELECT count(*) FROM raw.{table}'); print(f'raw.{table}: {cur.fetchone()[0]} rows')
        conn.commit()
if __name__=='__main__': main()
