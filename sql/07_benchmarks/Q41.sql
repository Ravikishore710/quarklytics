-- benchmark_query: Q41
SELECT d.calendar_date FROM analytics.dim_date d LEFT JOIN analytics.fact_orders o ON o.purchase_date_key=d.date_key WHERE o.order_id IS NULL;
