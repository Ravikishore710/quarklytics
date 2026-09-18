-- query_id: Q12
-- question: What is customer lifetime revenue?
-- business_purpose: Use customer_unique_id to aggregate across order-specific customer rows.
-- grain: customer_unique_id
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: CTE, GROUP BY
SELECT d.customer_unique_id, count(*) order_count, sum(o.total_order_value) lifetime_revenue FROM analytics.fact_orders o JOIN analytics.dim_customer d ON d.customer_key=o.customer_key GROUP BY 1 ORDER BY lifetime_revenue DESC;

-- query_id: Q13
-- question: How does each category rank by revenue in each month?
-- business_purpose: Build monthly category totals before applying a rank.
-- grain: month/category
-- tables: analytics.fact_order_items, analytics.dim_product, analytics.fact_orders
-- techniques: CTE, DENSE_RANK
WITH monthly AS (SELECT date_trunc('month',d.calendar_date)::date AS month,p.product_category_name_english category,sum(i.total_line_value) revenue FROM analytics.fact_order_items i JOIN analytics.fact_orders o USING(order_id) JOIN analytics.dim_date d ON d.date_key=o.purchase_date_key JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1,2) SELECT *, dense_rank() OVER(PARTITION BY month ORDER BY revenue DESC) category_rank FROM monthly ORDER BY month,category_rank;

-- query_id: Q14
-- question: What are late-delivery cohorts?
-- business_purpose: Group customers by first purchase month and compare lateness.
-- grain: cohort_month
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: CTE, date_trunc
WITH firsts AS (SELECT customer_key,min(purchase_date_key) first_date_key FROM analytics.fact_orders GROUP BY customer_key) SELECT left(first_date_key::text,6) cohort_month, count(*) orders, count(*) FILTER(WHERE is_late) late_orders FROM analytics.fact_orders o JOIN firsts f USING(customer_key) GROUP BY 1 ORDER BY 1;

-- query_id: Q15
-- question: How does each seller compare with marketplace average revenue?
-- business_purpose: Calculate seller totals and benchmark them against the overall average.
-- grain: seller
-- tables: analytics.fact_order_items, analytics.dim_seller
-- techniques: CTE, AVG
WITH sellers AS (SELECT seller_key,sum(total_line_value) revenue FROM analytics.fact_order_items GROUP BY seller_key), marketplace AS (SELECT avg(revenue) avg_revenue FROM sellers) SELECT s.*,m.avg_revenue,s.revenue-m.avg_revenue difference FROM sellers s CROSS JOIN marketplace m ORDER BY revenue DESC;

-- query_id: Q16
-- question: Which customers increased spend between consecutive months?
-- business_purpose: Compare monthly customer value with a prior-period CTE.
-- grain: customer/month
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: CTE, LAG
WITH monthly AS (SELECT customer_key,purchase_date_key/100 month_key,sum(total_order_value) spend FROM analytics.fact_orders GROUP BY 1,2), prior AS (SELECT *,lag(spend) OVER(PARTITION BY customer_key ORDER BY month_key) prior_spend FROM monthly) SELECT * FROM prior WHERE spend>coalesce(prior_spend,0) ORDER BY customer_key,month_key;
