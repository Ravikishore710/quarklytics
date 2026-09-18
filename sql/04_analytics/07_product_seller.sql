-- query_id: Q33
-- question: Which sellers have the highest gross merchandise value?
-- business_purpose: Rank sellers by price value.
-- grain: seller
-- tables: analytics.fact_order_items, analytics.dim_seller
-- techniques: GROUP BY, ORDER BY
SELECT s.seller_key,s.seller_state,sum(i.price) gmv,count(DISTINCT i.order_id) orders FROM analytics.fact_order_items i JOIN analytics.dim_seller s ON s.seller_key=i.seller_key GROUP BY 1,2 ORDER BY gmv DESC;

-- query_id: Q34
-- question: Which sellers are above the marketplace average?
-- business_purpose: Compare sellers with the mean seller revenue.
-- grain: seller
-- tables: analytics.fact_order_items
-- techniques: CTE, HAVING
WITH seller_revenue AS (SELECT seller_key,sum(total_line_value) revenue FROM analytics.fact_order_items GROUP BY 1), avg_revenue AS (SELECT avg(revenue) value FROM seller_revenue) SELECT s.* FROM seller_revenue s CROSS JOIN avg_revenue a WHERE s.revenue>a.value ORDER BY s.revenue DESC;

-- query_id: Q35
-- question: How concentrated is category revenue?
-- business_purpose: Compute category share and cumulative concentration.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: SUM OVER, ratio
WITH category AS (SELECT p.product_category_name_english category,sum(i.total_line_value) revenue FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1) SELECT *,100*revenue/NULLIF(sum(revenue) OVER(),0) revenue_share_pct,sum(revenue) OVER(ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cumulative_revenue FROM category ORDER BY revenue DESC;

-- query_id: Q36
-- question: Which products have unusually high freight-to-price ratios?
-- business_purpose: Surface products where shipping burden is high.
-- grain: product
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: NULLIF, HAVING
SELECT p.product_key,p.product_category_name_english category,sum(i.freight_value)/NULLIF(sum(i.price),0) freight_to_price_ratio FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1,2 HAVING sum(i.price)>0 ORDER BY freight_to_price_ratio DESC;

-- query_id: Q37
-- question: Which categories review better or worse than marketplace average?
-- business_purpose: Compare category review averages to all reviewed orders.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product, analytics.fact_orders
-- techniques: CTE, AVG
WITH category AS (SELECT p.product_category_name_english category,avg(o.review_score) avg_review FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key JOIN analytics.fact_orders o USING(order_id) WHERE o.review_score IS NOT NULL GROUP BY 1), marketplace AS (SELECT avg(review_score) avg_review FROM analytics.fact_orders WHERE review_score IS NOT NULL) SELECT c.*,c.avg_review-m.avg_review difference_vs_marketplace FROM category c CROSS JOIN marketplace m ORDER BY difference_vs_marketplace DESC;
