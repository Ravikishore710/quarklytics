-- query_id: Q17
-- question: What are the top three products within each category?
-- business_purpose: Rank products within category while retaining product rows.
-- grain: category/product
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: DENSE_RANK
WITH products AS (SELECT p.product_category_name_english category,p.product_key,sum(i.total_line_value) revenue FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1,2), ranked AS (SELECT *,dense_rank() OVER(PARTITION BY category ORDER BY revenue DESC) rnk FROM products) SELECT * FROM ranked WHERE rnk<=3 ORDER BY category,rnk;

-- query_id: Q18
-- question: What is seller revenue rank within each state?
-- business_purpose: Rank sellers against sellers in the same state.
-- grain: state/seller
-- tables: analytics.fact_order_items, analytics.dim_seller
-- techniques: RANK
WITH sellers AS (SELECT s.seller_state,s.seller_key,sum(i.total_line_value) revenue FROM analytics.fact_order_items i JOIN analytics.dim_seller s ON s.seller_key=i.seller_key GROUP BY 1,2) SELECT *,rank() OVER(PARTITION BY seller_state ORDER BY revenue DESC) state_rank FROM sellers ORDER BY seller_state,state_rank;

-- query_id: Q19
-- question: What is monthly revenue and month-over-month change?
-- business_purpose: Show revenue momentum with a prior-month comparison.
-- grain: month
-- tables: analytics.fact_order_items, analytics.fact_orders
-- techniques: LAG
WITH monthly AS (SELECT o.purchase_date_key/100 month_key,sum(o.total_order_value) revenue FROM analytics.fact_orders o GROUP BY 1) SELECT *,revenue-lag(revenue) OVER(ORDER BY month_key) mom_change FROM monthly ORDER BY month_key;

-- query_id: Q20
-- question: What is cumulative revenue over time?
-- business_purpose: Calculate a running total over ordered months.
-- grain: month
-- tables: analytics.fact_order_items, analytics.fact_orders
-- techniques: SUM OVER, window frame
WITH monthly AS (SELECT purchase_date_key/100 month_key,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1) SELECT *,sum(revenue) OVER(ORDER BY month_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cumulative_revenue FROM monthly ORDER BY month_key;

-- query_id: Q21
-- question: What is each customer’s order sequence?
-- business_purpose: Number orders for each underlying customer.
-- grain: customer/order
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: ROW_NUMBER
SELECT d.customer_unique_id,o.order_id,o.purchase_date_key,row_number() OVER(PARTITION BY o.customer_key ORDER BY o.purchase_date_key,o.order_id) order_sequence FROM analytics.fact_orders o JOIN analytics.dim_customer d ON d.customer_key=o.customer_key ORDER BY d.customer_unique_id,order_sequence;

-- query_id: Q22
-- question: How are customers distributed across revenue quartiles?
-- business_purpose: Bucket customers by lifetime value.
-- grain: customer
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: NTILE
WITH customer_value AS (SELECT customer_key,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1) SELECT *,ntile(4) OVER(ORDER BY revenue DESC) revenue_quartile FROM customer_value ORDER BY revenue DESC;
