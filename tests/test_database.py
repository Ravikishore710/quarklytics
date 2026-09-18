from __future__ import annotations
import os, pytest, psycopg
from dotenv import load_dotenv
load_dotenv()
def conninfo(): return os.getenv('DATABASE_URL') or f"host={os.getenv('POSTGRES_HOST','localhost')} port={os.getenv('POSTGRES_PORT','5432')} dbname={os.getenv('POSTGRES_DB','quarklytics')} user={os.getenv('POSTGRES_USER','quarklytics')} password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"
@pytest.fixture(scope='session')
def db():
    try:
        with psycopg.connect(conninfo()) as c: yield c
    except psycopg.OperationalError as e: pytest.skip(f'PostgreSQL unavailable: {e}')
def scalar(db,sql):
    with db.cursor() as cur: cur.execute(sql); return cur.fetchone()[0]
def test_required_tables_exist(db):
    assert scalar(db,"SELECT count(*) FROM information_schema.tables WHERE table_schema='raw' AND table_name IN ('customers','orders','order_items','order_payments','order_reviews','products','sellers','geolocation','category_translation')") == 9
    assert scalar(db,"SELECT count(*) FROM information_schema.tables WHERE table_schema='core'") >= 9
    assert scalar(db,"SELECT count(*) FROM information_schema.tables WHERE table_schema='analytics'") >= 6
def test_foreign_key_orphans_are_zero(db):
    assert scalar(db,"SELECT count(*) FROM core.orders o LEFT JOIN core.customers c USING(customer_id) WHERE c.customer_id IS NULL") == 0
    assert scalar(db,"SELECT count(*) FROM core.order_items i LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL") == 0
def test_fact_grains_are_unique(db):
    assert scalar(db,"SELECT count(*) - count(DISTINCT order_id) FROM analytics.fact_orders") == 0
    assert scalar(db,"SELECT count(*) - count(DISTINCT (order_id,order_item_id)) FROM analytics.fact_order_items") == 0
def test_metric_invariant(db):
    assert scalar(db,"SELECT count(*) FROM analytics.fact_orders WHERE total_order_value < item_value") == 0
def test_customer_key_is_underlying_customer(db):
    assert scalar(db,"SELECT count(*) FROM analytics.dim_customer WHERE customer_key <> customer_unique_id") == 0
def test_date_dimension_range(db):
    assert scalar(db,"SELECT min(calendar_date) FROM analytics.dim_date") is not None
    assert scalar(db,"SELECT max(calendar_date) FROM analytics.dim_date") is not None

def test_order_reviews_composite_grain(db):
    assert scalar(db,"SELECT count(*) - count(DISTINCT (review_id, order_id)) FROM core.order_reviews") == 0

def test_views_and_materialized_views_exist(db):
    assert scalar(db,"SELECT count(*) FROM information_schema.views WHERE table_schema='analytics' AND table_name IN ('v_order_value','v_customer_lifetime_value','v_monthly_revenue','v_delivery_performance','v_seller_performance')") == 5
    assert scalar(db,"SELECT count(*) FROM pg_matviews WHERE schemaname='analytics' AND matviewname IN ('mv_monthly_category_revenue','mv_seller_monthly_performance')") == 2

def test_all_42_analytical_queries_execute(db):
    from pathlib import Path
    import re
    root = Path(__file__).resolve().parents[1]
    files = sorted((root / 'sql/04_analytics').glob('0*.sql'))
    count = 0
    with db.cursor() as cur:
        for f in files:
            if f.name.startswith(('00_', '01_build', '02_build')):
                continue
            text = f.read_text(encoding='utf-8')
            blocks = re.split(r'(?=--\s*query_id:)', text)
            for b in blocks:
                b = b.strip()
                if not b.startswith('-- query_id:'):
                    continue
                lines = [l for l in b.splitlines() if not l.strip().startswith('--')]
                sql = '\n'.join(lines).strip()
                cur.execute(sql)
                assert cur.description is not None
                count += 1
    assert count == 42
