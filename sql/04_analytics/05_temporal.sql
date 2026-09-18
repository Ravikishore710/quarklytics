-- query_id: Q23
-- question: What is monthly revenue growth?
-- business_purpose: Compute absolute and percentage growth.
-- grain: month
-- tables: analytics.fact_order_items, analytics.fact_orders
-- techniques: DATE_TRUNC, LAG
WITH monthly AS (SELECT purchase_date_key/100 month_key,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1), changes AS (SELECT *,lag(revenue) OVER(ORDER BY month_key) prior_revenue FROM monthly) SELECT *,revenue-prior_revenue absolute_growth,100*(revenue-prior_revenue)/NULLIF(prior_revenue,0) pct_growth FROM changes ORDER BY month_key;

-- query_id: Q24
-- question: What is rolling three-month revenue?
-- business_purpose: Identify sustained revenue momentum.
-- grain: month
-- tables: analytics.fact_order_items, analytics.fact_orders
-- techniques: CTE, ROWS BETWEEN
WITH monthly AS (SELECT purchase_date_key/100 month_key,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1) SELECT *,sum(revenue) OVER(ORDER BY month_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) rolling_3_month_revenue FROM monthly ORDER BY month_key;

-- query_id: Q25
-- question: How do first and subsequent purchases differ?
-- business_purpose: Classify order sequence using customer_unique_id.
-- grain: order_sequence
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: ROW_NUMBER, CASE
WITH sequenced AS (SELECT o.*,row_number() OVER(PARTITION BY customer_key ORDER BY purchase_date_key,order_id) sequence FROM analytics.fact_orders o) SELECT sequence,count(*) orders,avg(total_order_value) avg_value,avg(delivery_days) avg_delivery_days FROM sequenced GROUP BY sequence ORDER BY sequence;

-- query_id: Q26
-- question: What is the time between customer orders?
-- business_purpose: Measure interpurchase intervals.
-- grain: customer/order
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: LAG, INTERVAL
WITH sequence AS (SELECT customer_key,to_date(purchase_date_key::text,'YYYYMMDD') purchase_date,lag(to_date(purchase_date_key::text,'YYYYMMDD')) OVER(PARTITION BY customer_key ORDER BY purchase_date_key) previous_date FROM analytics.fact_orders) SELECT customer_key,avg(purchase_date-previous_date) avg_days_between_orders FROM sequence WHERE previous_date IS NOT NULL GROUP BY customer_key ORDER BY avg_days_between_orders;

-- query_id: Q27
-- question: How has delivery time changed over time?
-- business_purpose: Trend delivered-order duration by month.
-- grain: month
-- tables: core.orders
-- techniques: DATE_TRUNC, AVG
SELECT purchase_date_key/100 month_key,avg(delivery_days) avg_delivery_days,percentile_cont(.5) WITHIN GROUP(ORDER BY delivery_days) median_delivery_days FROM analytics.fact_orders WHERE is_delivered GROUP BY 1 ORDER BY 1;
