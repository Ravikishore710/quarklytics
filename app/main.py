"""Quarklytics Premium Analytics & SQL Studio Backend."""
from __future__ import annotations
import os, re, time, csv
from pathlib import Path
from typing import Optional, List, Dict, Any

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / '.env')

app = FastAPI(title="Quarklytics Studio", version="2.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def conninfo() -> str:
    return os.getenv('DATABASE_URL') or (
        f"host={os.getenv('POSTGRES_HOST','localhost')} "
        f"port={os.getenv('POSTGRES_PORT','5432')} "
        f"dbname={os.getenv('POSTGRES_DB','quarklytics')} "
        f"user={os.getenv('POSTGRES_USER','quarklytics')} "
        f"password={os.getenv('POSTGRES_PASSWORD','change-me-locally')}"
    )

class QueryRequest(BaseModel):
    sql: str
    limit: Optional[int] = 500

class AskRequest(BaseModel):
    question: str

def parse_curriculum() -> List[Dict[str, Any]]:
    files = sorted((ROOT / 'sql/04_analytics').glob('0*.sql'))
    queries = []
    category_map = {
        '01_foundations': 'Foundations & Aggregations',
        '02_joins': 'Multi-Table Joins',
        '03_ctes': 'Common Table Expressions',
        '04_windows': 'Window Functions & Ranking',
        '05_temporal': 'Temporal & Cohort Analytics',
        '06_customer': 'Customer Lifetime & Retention',
        '07_product_seller': 'Product & Seller Economics',
        '08_postgresql': 'PostgreSQL Advanced Features',
    }
    for f in files:
        if f.name.startswith(('00_', '01_build', '02_build')):
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
            q_m = re.search(r'--\s*question:\s*(.+)', b)
            question = q_m.group(1).strip() if q_m else ""
            p_m = re.search(r'--\s*business_purpose:\s*(.+)', b)
            purpose = p_m.group(1).strip() if p_m else ""
            g_m = re.search(r'--\s*grain:\s*(.+)', b)
            grain = g_m.group(1).strip() if g_m else ""
            t_m = re.search(r'--\s*tables:\s*(.+)', b)
            tables = t_m.group(1).strip() if t_m else ""
            tech_m = re.search(r'--\s*techniques:\s*(.+)', b)
            techniques = tech_m.group(1).strip() if tech_m else ""
            lines = [l for l in b.splitlines() if not l.strip().startswith('--')]
            sql = '\n'.join(lines).strip()
            category = category_map.get(f.stem, f.stem)
            queries.append({
                "id": qid,
                "question": question,
                "purpose": purpose,
                "grain": grain,
                "tables": tables,
                "techniques": [t.strip() for t in techniques.split(',') if t.strip()],
                "category": category,
                "sql": sql
            })
    return queries

@app.get("/")
def serve_index():
    index_path = Path(__file__).resolve().parent / "index.html"
    if not index_path.exists():
        raise HTTPException(status_code=404, detail="index.html not found")
    return FileResponse(index_path, media_type="text/html")

@app.get("/api/kpis")
def get_kpis():
    try:
        with psycopg.connect(conninfo()) as conn:
            with conn.cursor() as cur:
                # Total orders, GMV, total value, avg review
                cur.execute("""
                    SELECT 
                        count(*) as total_orders,
                        sum(item_value) as gmv,
                        sum(total_order_value) as total_value,
                        avg(review_score) as avg_review,
                        percentile_cont(0.5) WITHIN GROUP (ORDER BY delivery_days) as median_delivery_days
                    FROM analytics.fact_orders
                """)
                row = cur.fetchone()
                total_orders, gmv, total_value, avg_review, median_delivery = row

                # Repeat customers
                cur.execute("""
                    WITH counts AS (
                        SELECT customer_key, count(*) as cnt 
                        FROM analytics.fact_orders GROUP BY customer_key
                    )
                    SELECT count(*), count(*) FILTER (WHERE cnt > 1) FROM counts
                """)
                cust_row = cur.fetchone()
                total_cust, repeat_cust = cust_row
                repeat_rate = round(100.0 * repeat_cust / max(total_cust, 1), 2)

                # Total products and sellers
                cur.execute("SELECT count(*) FROM analytics.dim_product")
                total_products = cur.fetchone()[0]
                cur.execute("SELECT count(*) FROM analytics.dim_seller")
                total_sellers = cur.fetchone()[0]

                return {
                    "total_orders": total_orders,
                    "total_gmv": float(gmv or 0),
                    "total_order_value": float(total_value or 0),
                    "avg_review_score": round(float(avg_review or 0), 2),
                    "median_delivery_days": round(float(median_delivery or 0), 1),
                    "total_customers": total_cust,
                    "repeat_customers": repeat_cust,
                    "repeat_rate_pct": repeat_rate,
                    "total_products": total_products,
                    "total_sellers": total_sellers,
                    "status": "healthy"
                }
    except Exception as e:
        return {"error": str(e), "status": "error"}

@app.post("/api/query")
def execute_query(req: QueryRequest):
    sql = req.sql.strip()
    if not sql:
        raise HTTPException(status_code=400, detail="SQL query string is empty")

    # Safety check: prevent dropping/truncating in regular studio queries
    lower_sql = sql.lower()
    dangerous = ['drop table', 'drop schema', 'drop database', 'truncate ']
    for d in dangerous:
        if d in lower_sql:
            raise HTTPException(status_code=403, detail=f"Destructive commands ('{d}') are restricted in the interactive studio.")

    start_time = time.perf_counter()
    try:
        with psycopg.connect(conninfo()) as conn:
            with conn.cursor() as cur:
                cur.execute(sql)
                elapsed_ms = (time.perf_counter() - start_time) * 1000
                if cur.description:
                    columns = [d[0] for d in cur.description]
                    raw_rows = cur.fetchall()
                    total_count = len(raw_rows)
                    # Apply limit for display response
                    bounded_rows = raw_rows[:req.limit]
                    # Format types nicely for JSON serialization
                    formatted_rows = []
                    for r in bounded_rows:
                        formatted_rows.append([
                            str(val) if val is not None else None 
                            for val in r
                        ])
                    return {
                        "success": True,
                        "columns": columns,
                        "rows": formatted_rows,
                        "total_rows": total_count,
                        "returned_rows": len(bounded_rows),
                        "execution_ms": round(elapsed_ms, 2),
                    }
                else:
                    conn.commit()
                    return {
                        "success": True,
                        "columns": ["Result"],
                        "rows": [["Command executed successfully"]],
                        "total_rows": 1,
                        "returned_rows": 1,
                        "execution_ms": round(elapsed_ms, 2),
                    }
    except Exception as e:
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        return {
            "success": False,
            "error": str(e),
            "execution_ms": round(elapsed_ms, 2)
        }

@app.get("/api/curriculum")
def get_curriculum():
    return parse_curriculum()

@app.get("/api/schema")
def get_schema():
    try:
        with psycopg.connect(conninfo()) as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        table_schema, 
                        table_name, 
                        table_type 
                    FROM information_schema.tables 
                    WHERE table_schema IN ('analytics', 'core', 'raw')
                    ORDER BY table_schema, table_name
                """)
                tables = []
                for s, name, t_type in cur.fetchall():
                    # get row count
                    try:
                        cur.execute(f'SELECT count(*) FROM "{s}"."{name}"')
                        count = cur.fetchone()[0]
                    except Exception:
                        count = 0
                    
                    # get columns
                    cur.execute("""
                        SELECT column_name, data_type, is_nullable
                        FROM information_schema.columns
                        WHERE table_schema = %s AND table_name = %s
                        ORDER BY ordinal_position
                    """, (s, name))
                    cols = cur.fetchall()
                    
                    tables.append({
                        "schema": s,
                        "name": name,
                        "type": "View" if "VIEW" in t_type else "Table",
                        "row_count": count,
                        "columns": [{"name": c[0], "type": c[1], "nullable": c[2] == "YES"} for c in cols]
                    })
                
                # Materialized views
                cur.execute("""
                    SELECT schemaname, matviewname 
                    FROM pg_matviews 
                    WHERE schemaname = 'analytics'
                """)
                for s, name in cur.fetchall():
                    cur.execute(f'SELECT count(*) FROM "{s}"."{name}"')
                    count = cur.fetchone()[0]
                    cur.execute("""
                        SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod)
                        FROM pg_attribute a
                        JOIN pg_class c ON c.oid = a.attrelid
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE n.nspname = %s AND c.relname = %s AND a.attnum > 0 AND NOT a.attisdropped
                        ORDER BY a.attnum
                    """, (s, name))
                    cols = cur.fetchall()
                    tables.append({
                        "schema": s,
                        "name": name,
                        "type": "Materialized View",
                        "row_count": count,
                        "columns": [{"name": c[0], "type": c[1], "nullable": True} for c in cols]
                    })
                return tables
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/benchmarks")
def get_benchmarks():
    csv_path = ROOT / 'evaluation/query_benchmarks.csv'
    if not csv_path.exists():
        return []
    with csv_path.open('r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        return list(reader)

@app.post("/api/ask")
def natural_language_ask(req: AskRequest):
    q = req.question.strip().lower()

    # Check custom advanced business questions first
    if ("destroy" in q or "collapse" in q or "threshold" in q) or ("delay" in q and "review" in q) or ("score" in q and "delay" in q):
        return {
            "match_type": "custom",
            "title": "The Delivery Delay Cliff & Review Score Collapse",
            "sql": """SELECT 
    CASE 
        WHEN NOT is_delivered THEN '5. Undelivered / In-Transit'
        WHEN NOT is_late THEN '1. On Time / Early'
        WHEN delivery_days - estimated_delivery_days <= 3 THEN '2. 1 to 3 Days Late'
        WHEN delivery_days - estimated_delivery_days <= 7 THEN '3. 4 to 7 Days Late'
        ELSE '4. 8+ Days Late'
    END AS delivery_status,
    count(*) AS total_orders,
    round(avg(review_score), 2) AS avg_review_score,
    round(100.0 * count(*) FILTER (WHERE review_score = 1) / count(*), 1) AS pct_1_star,
    round(100.0 * count(*) FILTER (WHERE review_score = 5) / count(*), 1) AS pct_5_star
FROM analytics.fact_orders
WHERE review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;"""
        }

    if "installment" in q or "parcela" in q or "financing" in q:
        return {
            "match_type": "custom",
            "title": "Credit Card Installments vs Customer Order Value",
            "sql": """SELECT 
    CASE 
        WHEN payment_installments = 1 THEN '1. Upfront (1 Installment)'
        WHEN payment_installments BETWEEN 2 AND 3 THEN '2. Short (2-3 Installments)'
        WHEN payment_installments BETWEEN 4 AND 6 THEN '3. Medium (4-6 Installments)'
        WHEN payment_installments BETWEEN 7 AND 10 THEN '4. Long (7-10 Installments)'
        ELSE '5. Extended (11+ Installments)'
    END AS installment_tier,
    count(DISTINCT p.order_id) AS order_count,
    round(avg(p.payment_value), 2) AS avg_order_spend,
    round(sum(p.payment_value) / 1000000.0, 2) AS total_volume_m,
    round(avg(p.payment_installments), 1) AS avg_installments
FROM core.order_payments p
WHERE p.payment_type = 'credit_card'
GROUP BY 1
ORDER BY installment_tier;"""
        }

    if "cross" in q or "corridor" in q or "freight penalty" in q or "local fulfillment" in q or "different state" in q or "same state" in q:
        return {
            "match_type": "custom",
            "title": "Local vs Cross-Border Shipping Penalty & Delivery Duration",
            "sql": """SELECT 
    CASE 
        WHEN s.seller_state = c.customer_state THEN '1. Local (Same State Fulfillment)'
        ELSE '2. Cross-Border (Inter-State Fulfillment)'
    END AS trade_corridor,
    count(*) AS total_items_sold,
    round(avg(i.freight_value), 2) AS avg_freight_cost,
    round(avg(i.price), 2) AS avg_product_price,
    round(100.0 * avg(i.freight_value / nullif(i.price, 0)), 1) AS avg_freight_burden_pct,
    round(avg(o.delivery_days), 1) AS avg_delivery_days
FROM analytics.fact_order_items i
JOIN analytics.fact_orders o USING (order_id)
JOIN analytics.dim_customer c ON c.customer_key = o.customer_key
JOIN analytics.dim_seller s ON s.seller_key = i.seller_key
WHERE o.is_delivered
GROUP BY 1
ORDER BY 1;"""
        }

    curriculum = parse_curriculum()

    # Score matches against question, purpose, techniques
    best_match = None
    best_score = 0
    keywords = re.findall(r'\w+', q)

    for item in curriculum:
        text = f"{item['id']} {item['question']} {item['purpose']} {item['grain']} {' '.join(item['techniques'])}".lower()
        score = sum(2 for kw in keywords if kw in item['question'].lower())
        score += sum(1 for kw in keywords if kw in text)
        if score > best_score:
            best_score = score
            best_match = item

    # Common semantic patterns fallback
    if best_score < 2:
        if "category" in q or "categories" in q:
            return {"match_type": "generated", "title": "Top Categories by Revenue", "sql": "SELECT coalesce(p.product_category_name_english, p.product_category_name, 'unknown') as category, sum(i.total_line_value) as revenue FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key = i.product_key GROUP BY 1 ORDER BY revenue DESC LIMIT 10;"}
        elif "repeat" in q or "loyal" in q:
            return {"match_type": "curriculum", "title": "Repeat Customer Rate (Q28)", "id": "Q28", "sql": curriculum[27]['sql']}
        elif "deliver" in q or "late" in q:
            return {"match_type": "curriculum", "title": "Delivery Distribution (Q38)", "id": "Q38", "sql": curriculum[37]['sql']}
        elif "month" in q or "growth" in q:
            return {"match_type": "curriculum", "title": "Monthly Revenue Growth (Q23)", "id": "Q23", "sql": curriculum[22]['sql']}
        elif "vip" in q or "top customer" in q:
            return {"match_type": "curriculum", "title": "Top Customers by Lifetime Value (Q29)", "id": "Q29", "sql": curriculum[28]['sql']}
        else:
            # Return Q01 by default
            return {"match_type": "curriculum", "title": f"Closest Query: {curriculum[0]['question']} (Q01)", "id": "Q01", "sql": curriculum[0]['sql']}

    return {
        "match_type": "curriculum",
        "title": f"{best_match['id']} — {best_match['question']}",
        "id": best_match['id'],
        "purpose": best_match['purpose'],
        "sql": best_match['sql']
    }
