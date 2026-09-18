-- Compare these actual counts with data/manifests/dataset.yml and source expectations.
SELECT 'raw.customers' table_name, count(*) row_count FROM raw.customers
UNION ALL SELECT 'raw.orders', count(*) FROM raw.orders
UNION ALL SELECT 'raw.order_items', count(*) FROM raw.order_items
UNION ALL SELECT 'raw.order_payments', count(*) FROM raw.order_payments
UNION ALL SELECT 'raw.order_reviews', count(*) FROM raw.order_reviews
UNION ALL SELECT 'raw.products', count(*) FROM raw.products
UNION ALL SELECT 'raw.sellers', count(*) FROM raw.sellers
UNION ALL SELECT 'raw.geolocation', count(*) FROM raw.geolocation
UNION ALL SELECT 'raw.category_translation', count(*) FROM raw.category_translation
ORDER BY table_name;
