SELECT 'negative_item_price' check_name, count(*) violations FROM core.order_items WHERE price < 0
UNION ALL SELECT 'negative_freight_value', count(*) FROM core.order_items WHERE freight_value < 0
UNION ALL SELECT 'invalid_review_score', count(*) FROM core.order_reviews WHERE review_score NOT BETWEEN 1 AND 5
UNION ALL SELECT 'approval_before_purchase', count(*) FROM core.orders WHERE order_approved_at < order_purchase_timestamp
UNION ALL SELECT 'carrier_before_approval', count(*) FROM core.orders WHERE order_delivered_carrier_date < COALESCE(order_approved_at, order_purchase_timestamp)
UNION ALL SELECT 'delivery_before_carrier', count(*) FROM core.orders WHERE order_delivered_customer_date < order_delivered_carrier_date
UNION ALL SELECT 'delivery_before_purchase', count(*) FROM core.orders WHERE order_delivered_customer_date < order_purchase_timestamp;
