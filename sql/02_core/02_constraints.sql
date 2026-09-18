CREATE INDEX IF NOT EXISTS ix_core_orders_customer_id ON core.orders(customer_id);
CREATE INDEX IF NOT EXISTS ix_core_order_items_product_id ON core.order_items(product_id);
CREATE INDEX IF NOT EXISTS ix_core_order_items_seller_id ON core.order_items(seller_id);
CREATE INDEX IF NOT EXISTS ix_core_payments_order_id ON core.order_payments(order_id);
CREATE INDEX IF NOT EXISTS ix_core_reviews_order_id ON core.order_reviews(order_id);
CREATE INDEX IF NOT EXISTS ix_core_customers_state ON core.customers(customer_state);
