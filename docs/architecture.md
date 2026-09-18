# Architecture

Quarklytics uses a three-layer database architecture. `raw` preserves source CSV shape as text so ingestion can be audited. `core` converts values to PostgreSQL types and enforces relational constraints. `analytics` presents reusable dimensions and facts for SQL analysis.

## Grain and join safety

- `core.orders`: one row per order.
- `core.order_items`: one row per order line, key `(order_id, order_item_id)`.
- `core.order_payments`: one row per payment sequence within an order.
- `core.order_reviews`: one row per review identifier; an order may have multiple review rows.
- `analytics.fact_orders`: one row per order. Item and review aggregates are reduced before joining.
- `analytics.fact_order_items`: one row per product line within an order.

Never join `fact_orders` and `fact_order_items` without understanding the resulting grain. Query Q11 uses a line-level CTE and dimensional joins to prevent accidental revenue multiplication.

## Pipeline

1. Create schemas and raw tables.
2. `COPY` raw CSVs with Python using parameterized local paths.
3. Transform raw text to typed core tables.
4. Run row-count, integrity, null, domain, and temporal checks.
5. Generate `dim_date` with PostgreSQL `generate_series`.
6. Build dimensions and facts.
7. Create views/materialized views.
8. Capture baseline plans, create targeted indexes, run `ANALYZE`, and capture optimized plans.

## Design decisions

- `customer_unique_id` is the analytical customer key because `customer_id` is an order-specific record key.
- Geolocation uses an identity surrogate key because ZIP prefixes are repeated observations.
- Money-like values use `numeric`, never floating-point arithmetic.
- Nullable source dates remain nullable; missing delivery dates are not fabricated.
