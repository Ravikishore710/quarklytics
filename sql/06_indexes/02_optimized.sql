-- Targeted indexes selected for the benchmark workload, not blanket indexing.
CREATE INDEX IF NOT EXISTS ix_orders_purchase_timestamp ON core.orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS ix_orders_customer_id ON core.orders(customer_id);
CREATE INDEX IF NOT EXISTS ix_order_items_order_id ON core.order_items(order_id);
CREATE INDEX IF NOT EXISTS ix_order_items_product_id ON core.order_items(product_id);
CREATE INDEX IF NOT EXISTS ix_order_items_seller_id ON core.order_items(seller_id);
CREATE INDEX IF NOT EXISTS ix_payments_order_id ON core.order_payments(order_id);
CREATE INDEX IF NOT EXISTS ix_reviews_order_id ON core.order_reviews(order_id);
CREATE INDEX IF NOT EXISTS ix_customers_state ON core.customers(customer_state);
CREATE INDEX IF NOT EXISTS ix_products_category ON core.products(product_category_name);
ANALYZE;
