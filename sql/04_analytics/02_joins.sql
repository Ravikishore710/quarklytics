-- query_id: Q06
-- question: What are the top categories by total order value?
-- business_purpose: Rank categories using item plus freight value.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: JOIN, GROUP BY
SELECT coalesce(p.product_category_name_english,p.product_category_name,'unknown') category, sum(i.total_line_value) total_value FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1 ORDER BY total_value DESC;

-- query_id: Q07
-- question: What is seller revenue by state?
-- business_purpose: Compare seller value across seller regions.
-- grain: seller_state
-- tables: analytics.fact_order_items, analytics.dim_seller
-- techniques: LEFT JOIN, GROUP BY
SELECT s.seller_state, s.seller_key, sum(i.total_line_value) revenue FROM analytics.fact_order_items i LEFT JOIN analytics.dim_seller s ON s.seller_key=i.seller_key GROUP BY 1,2 ORDER BY revenue DESC;

-- query_id: Q08
-- question: What is average review score by category?
-- business_purpose: Relate reviewed orders to the products sold in them.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product, analytics.fact_orders
-- techniques: JOIN, AVG, NULL handling
SELECT coalesce(p.product_category_name_english,p.product_category_name,'unknown') category, avg(o.review_score) avg_review FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key JOIN analytics.fact_orders o USING(order_id) GROUP BY 1 ORDER BY avg_review DESC NULLS LAST;

-- query_id: Q09
-- question: How does delivery performance vary by customer state?
-- business_purpose: Measure delivery and late-rate differences by destination.
-- grain: state
-- tables: analytics.fact_orders, analytics.dim_customer
-- techniques: JOIN, CASE, FILTER
SELECT c.customer_state, avg(o.delivery_days) avg_delivery_days, count(*) FILTER (WHERE o.is_late) late_orders, count(*) FILTER (WHERE o.is_delivered) delivered_orders FROM analytics.fact_orders o JOIN analytics.dim_customer c ON c.customer_key=o.customer_key GROUP BY 1 ORDER BY avg_delivery_days DESC NULLS LAST;

-- query_id: Q10
-- question: How does payment method relate to order value?
-- business_purpose: Compare payment values and orders by tender.
-- grain: payment_type
-- tables: core.order_payments, analytics.fact_orders
-- techniques: JOIN, GROUP BY
SELECT p.payment_type, avg(o.total_order_value) avg_order_value, count(DISTINCT p.order_id) orders FROM core.order_payments p JOIN analytics.fact_orders o USING(order_id) GROUP BY 1 ORDER BY avg_order_value DESC;

-- query_id: Q11
-- question: How do category, seller, and customer regions interact?
-- business_purpose: Produce a three-way regional category view without incompatible fact multiplication.
-- grain: category/seller_state/customer_state
-- tables: analytics.fact_order_items, analytics.dim_product, analytics.dim_seller, analytics.fact_orders, analytics.dim_customer
-- techniques: multi-table JOIN, CTE
WITH line AS (SELECT i.order_id,i.product_key,i.seller_key,i.total_line_value FROM analytics.fact_order_items i) SELECT p.product_category_name_english category,s.seller_state,c.customer_state,sum(line.total_line_value) value FROM line JOIN analytics.dim_product p ON p.product_key=line.product_key JOIN analytics.dim_seller s ON s.seller_key=line.seller_key JOIN analytics.fact_orders o USING(order_id) JOIN analytics.dim_customer c ON c.customer_key=o.customer_key GROUP BY 1,2,3 ORDER BY value DESC;
