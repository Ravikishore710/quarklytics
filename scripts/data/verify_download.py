"""Verify the nine expected Olist files and optionally write SHA-256 checksums."""
from __future__ import annotations
import argparse, hashlib
from pathlib import Path

EXPECTED = [
    'olist_customers_dataset.csv','olist_orders_dataset.csv','olist_order_items_dataset.csv',
    'olist_order_payments_dataset.csv','olist_order_reviews_dataset.csv','olist_products_dataset.csv',
    'olist_sellers_dataset.csv','olist_geolocation_dataset.csv','product_category_name_translation.csv',
]
def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--raw-dir',type=Path,default=Path('data/raw')); ap.add_argument('--write-checksums',action='store_true'); args=ap.parse_args()
    missing=[n for n in EXPECTED if not (args.raw_dir/n).exists()]
    if missing:
        raise SystemExit('Missing files:\n  ' + '\n  '.join(missing))
    lines=[]
    for name in EXPECTED:
        p=args.raw_dir/name; digest=sha256(p); lines.append(f'{digest}  {name}'); print(f'{name}: {p.stat().st_size} bytes {digest}')
    if args.write_checksums:
        out=Path('data/checksums/olist.sha256'); out.parent.mkdir(parents=True,exist_ok=True); out.write_text('\n'.join(lines)+'\n'); print(f'Wrote {out}')
if __name__ == '__main__': main()
