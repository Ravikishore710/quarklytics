-- query_id: Q28
-- question: What is the repeat-customer rate?
-- business_purpose: Measure repeat behavior using customer_unique_id.
-- grain: customer_unique_id
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: COUNT, FILTER
WITH counts AS (SELECT customer_key,count(*) order_count FROM analytics.fact_orders GROUP BY customer_key) SELECT count(*) customers,count(*) FILTER(WHERE order_count>1) repeat_customers,100.0*count(*) FILTER(WHERE order_count>1)/NULLIF(count(*),0) repeat_rate_pct FROM counts;

-- query_id: Q29
-- question: Who are the top customers by lifetime value?
-- business_purpose: Identify high-value underlying customers.
-- grain: customer_unique_id
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: GROUP BY, ORDER BY
SELECT d.customer_unique_id,sum(o.total_order_value) lifetime_value,count(*) orders FROM analytics.fact_orders o JOIN analytics.dim_customer d ON d.customer_key=o.customer_key GROUP BY 1 ORDER BY lifetime_value DESC LIMIT 100;

-- query_id: Q30
-- question: What are customer revenue deciles?
-- business_purpose: Distribute customers across ten lifetime-value buckets.
-- grain: decile
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: NTILE
WITH values AS (SELECT customer_key,sum(total_order_value) lifetime_value FROM analytics.fact_orders GROUP BY 1) SELECT *,ntile(10) OVER(ORDER BY lifetime_value DESC) revenue_decile FROM values ORDER BY lifetime_value DESC;

-- query_id: Q31
-- question: How do first orders compare with repeat orders?
-- business_purpose: Compare value and lateness by purchase sequence.
-- grain: sequence
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: CTE, ROW_NUMBER
WITH sequence AS (SELECT o.*,row_number() OVER(PARTITION BY customer_key ORDER BY purchase_date_key,order_id) seq FROM analytics.fact_orders o) SELECT seq,count(*) orders,avg(total_order_value) avg_value,avg(review_score) avg_review FROM sequence GROUP BY seq ORDER BY seq;

-- query_id: Q32
-- question: What is average time between purchases?
-- business_purpose: Summarize interpurchase time for repeat customers.
-- grain: customer_unique_id
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: LAG, AVG
WITH sequence AS (SELECT customer_key,to_date(purchase_date_key::text,'YYYYMMDD') purchase_date,lag(to_date(purchase_date_key::text,'YYYYMMDD')) OVER(PARTITION BY customer_key ORDER BY purchase_date_key) prior_date FROM analytics.fact_orders) SELECT avg(purchase_date-prior_date) avg_days_between_repeat_orders FROM sequence WHERE prior_date IS NOT NULL;
