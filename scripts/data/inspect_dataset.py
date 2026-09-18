"""Print CSV row counts and columns without loading analytical logic into Python."""
from __future__ import annotations
import argparse,csv
from pathlib import Path
EXPECTED=['olist_customers_dataset.csv','olist_orders_dataset.csv','olist_order_items_dataset.csv','olist_order_payments_dataset.csv','olist_order_reviews_dataset.csv','olist_products_dataset.csv','olist_sellers_dataset.csv','olist_geolocation_dataset.csv','product_category_name_translation.csv']
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--raw-dir',type=Path,default=Path('data/raw')); a=ap.parse_args()
    for name in EXPECTED:
        p=a.raw_dir/name
        if not p.exists(): print(f'{name}: MISSING'); continue
        with p.open(encoding='utf-8-sig',newline='') as f:
            r=csv.reader(f); header=next(r); count=sum(1 for _ in r)
        print(f'{name}: rows={count:,}; columns={len(header)}; header={header}')
if __name__=='__main__': main()
