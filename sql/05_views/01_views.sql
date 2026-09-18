CREATE OR REPLACE VIEW analytics.v_order_value AS
SELECT order_id, customer_key, purchase_date_key, order_status, item_value, freight_value,
       total_order_value, is_delivered, is_late FROM analytics.fact_orders;
CREATE OR REPLACE VIEW analytics.v_customer_lifetime_value AS
SELECT customer_key, count(*) order_count, sum(total_order_value) lifetime_value,
       avg(total_order_value) average_order_value FROM analytics.fact_orders GROUP BY customer_key;
CREATE OR REPLACE VIEW analytics.v_monthly_revenue AS
SELECT purchase_date_key / 100 month_key, sum(item_value) item_revenue,
       sum(freight_value) freight_revenue, sum(total_order_value) total_revenue,
       count(*) order_count FROM analytics.fact_orders GROUP BY 1;
CREATE OR REPLACE VIEW analytics.v_delivery_performance AS
SELECT purchase_date_key / 100 month_key, count(*) FILTER(WHERE is_delivered) delivered_orders,
       count(*) FILTER(WHERE is_late) late_orders, avg(delivery_days) avg_delivery_days
FROM analytics.fact_orders GROUP BY 1;
CREATE OR REPLACE VIEW analytics.v_seller_performance AS
SELECT seller_key, count(DISTINCT order_id) order_count, sum(price) item_revenue,
       sum(total_line_value) total_line_value FROM analytics.fact_order_items GROUP BY seller_key;
