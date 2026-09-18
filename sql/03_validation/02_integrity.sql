-- Each result should be zero unless a source anomaly is being investigated.
SELECT 'customers_duplicate_pk' check_name, count(*) - count(DISTINCT customer_id) violations FROM core.customers
UNION ALL SELECT 'orders_without_customers', count(*) FROM core.orders o LEFT JOIN core.customers c USING(customer_id) WHERE c.customer_id IS NULL
UNION ALL SELECT 'items_without_orders', count(*) FROM core.order_items i LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'items_without_products', count(*) FROM core.order_items i LEFT JOIN core.products p USING(product_id) WHERE p.product_id IS NULL
UNION ALL SELECT 'items_without_sellers', count(*) FROM core.order_items i LEFT JOIN core.sellers s USING(seller_id) WHERE s.seller_id IS NULL
UNION ALL SELECT 'payments_without_orders', count(*) FROM core.order_payments p LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL
UNION ALL SELECT 'reviews_without_orders', count(*) FROM core.order_reviews r LEFT JOIN core.orders o USING(order_id) WHERE o.order_id IS NULL;
