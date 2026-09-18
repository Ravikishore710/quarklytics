-- query_id: Q01
-- question: What is monthly order volume?
-- business_purpose: Track order demand over time.
-- grain: month
-- tables: core.orders
-- techniques: GROUP BY, date_trunc
SELECT date_trunc('month', order_purchase_timestamp)::date AS month, count(*) AS order_count FROM core.orders GROUP BY 1 ORDER BY 1;

-- query_id: Q02
-- question: Which product categories generate the most item revenue?
-- business_purpose: Compare category-level item value without freight.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: JOIN, GROUP BY, COALESCE
SELECT coalesce(p.product_category_name_english, p.product_category_name, 'unknown') AS category, sum(i.price) AS item_revenue FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key = i.product_key GROUP BY 1 ORDER BY item_revenue DESC;

-- query_id: Q03
-- question: How does item revenue vary by customer state?
-- business_purpose: Regionalize order-line value through order/customer relationships.
-- grain: state
-- tables: analytics.fact_order_items, analytics.fact_orders, analytics.dim_customer
-- techniques: JOIN, CASE
SELECT c.customer_state, sum(i.total_line_value) AS line_value FROM analytics.fact_order_items i JOIN analytics.fact_orders o USING(order_id) JOIN analytics.dim_customer c ON c.customer_key=o.customer_key GROUP BY c.customer_state ORDER BY line_value DESC;

-- query_id: Q04
-- question: What is the payment-method distribution?
-- business_purpose: Understand tender mix and payment values.
-- grain: payment_type
-- tables: core.order_payments
-- techniques: GROUP BY, FILTER
SELECT payment_type, count(DISTINCT order_id) AS orders, sum(payment_value) AS payment_value FROM core.order_payments GROUP BY payment_type ORDER BY payment_value DESC;

-- query_id: Q05
-- question: What is average order value by year?
-- business_purpose: Compare annual order economics using the defined denominator.
-- grain: year
-- tables: analytics.fact_orders, analytics.dim_date
-- techniques: JOIN, HAVING
SELECT extract(year FROM d.calendar_date)::int AS year, avg(o.total_order_value) AS aov, count(*) AS order_count FROM analytics.fact_orders o JOIN analytics.dim_date d ON d.date_key=o.purchase_date_key WHERE o.total_order_value IS NOT NULL GROUP BY 1 HAVING count(*) > 0 ORDER BY 1;
