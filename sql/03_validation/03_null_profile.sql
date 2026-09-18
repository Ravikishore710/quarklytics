SELECT 'orders.order_approved_at' column_name, count(*) FILTER (WHERE order_approved_at IS NULL) null_count, count(*) total_count FROM core.orders
UNION ALL SELECT 'orders.order_delivered_carrier_date', count(*) FILTER (WHERE order_delivered_carrier_date IS NULL), count(*) FROM core.orders
UNION ALL SELECT 'orders.order_delivered_customer_date', count(*) FILTER (WHERE order_delivered_customer_date IS NULL), count(*) FROM core.orders
UNION ALL SELECT 'products.product_category_name', count(*) FILTER (WHERE product_category_name IS NULL), count(*) FROM core.products
UNION ALL SELECT 'reviews.review_score', count(*) FILTER (WHERE review_score IS NULL), count(*) FROM core.order_reviews;
