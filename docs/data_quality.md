# Data quality and validation

Validation is reporting-first: source anomalies are surfaced rather than silently corrected.

- `01_row_counts.sql` compares actual counts with source expectations.
- `02_integrity.sql` reports duplicate-key and foreign-key orphan conditions.
- `03_null_profile.sql` profiles important nullable columns.
- `04_domain_checks.sql` checks nonnegative monetary fields, review score range, and event ordering.

The enforced core foreign keys should yield zero orphan rows after transformation. Timeline anomalies are informative because real source records may not satisfy idealized chronology. Review and delivery nulls are expected for incomplete orders.

## Full Dataset Validation Findings

### 1. Row Counts and Coverage
All 9 source files loaded with exact fidelity:
- `raw.customers`: 99,441 rows
- `raw.orders`: 99,441 rows
- `raw.order_items`: 112,650 rows
- `raw.order_payments`: 103,886 rows
- `raw.order_reviews`: 99,224 rows
- `raw.products`: 32,951 rows
- `raw.sellers`: 3,095 rows
- `raw.geolocation`: 1,000,163 rows
- `raw.category_translation`: 71 rows

### 2. Referential Integrity & Foreign Keys
Zero foreign key orphans were detected across the entire relational model:
- `items_without_sellers`: 0
- `items_without_products`: 0
- `payments_without_orders`: 0
- `items_without_orders`: 0
- `orders_without_customers`: 0
- `reviews_without_orders`: 0
- `customers_duplicate_pk`: 0

### 3. Key Anomaly: Order Reviews Composite Primary Key
In `olist_order_reviews_dataset.csv`, 789 review IDs appear more than once (99,224 total rows across 98,410 distinct review IDs). Investigation revealed that when a customer places an order involving multiple shipments or separate orders in a single session, Olist assigns the identical review feedback to each corresponding order.  
- Unique grain: `(review_id, order_id)` is 100% unique (0 duplicates across 99,224 rows).
- Schema implementation: `core.order_reviews` enforces `PRIMARY KEY (review_id, order_id)`.

### 4. Domain & Timeline Validation
- Non-negative price violations: 0
- Non-negative freight violations: 0
- Invalid review scores (< 1 or > 5): 0
- Delivery before purchase: 0
- Carrier date before approval: **1,359 orders** (operational delay in payment approval logging vs immediate seller fulfillment)
- Delivery date before carrier date: **23 orders** (local pickup or logistics tracking sequence anomalies)
All timeline anomalies reflect real-world logistics operations and are preserved transparently.

### 5. Null Profile
- `products.product_category_name`: 610 missing category names (mapped to `'unknown'` in analytics layer)
- `orders.order_approved_at`: 160 missing approvals (unapproved or canceled orders)
- `orders.order_delivered_carrier_date`: 1,783 missing carrier dispatches
- `orders.order_delivered_customer_date`: 2,965 undelivered orders (in-flight, processing, or canceled)
- `reviews.review_score`: 0 missing scores

