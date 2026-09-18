-- query_id: Q38
-- question: What is the delivery-time percentile distribution?
-- business_purpose: Use continuous percentiles to show delivery spread.
-- grain: marketplace
-- tables: analytics.fact_orders
-- techniques: percentile_cont
SELECT percentile_cont(.5) WITHIN GROUP(ORDER BY delivery_days) median_days,percentile_cont(.9) WITHIN GROUP(ORDER BY delivery_days) p90_days FROM analytics.fact_orders WHERE is_delivered;

-- query_id: Q39
-- question: What is the conditional delivery/review summary?
-- business_purpose: Use FILTER for concise conditional statistics.
-- grain: marketplace
-- tables: analytics.fact_orders
-- techniques: FILTER
SELECT count(*) total_orders,count(*) FILTER(WHERE is_delivered) delivered_orders,count(*) FILTER(WHERE is_late) late_orders,avg(review_score) FILTER(WHERE is_delivered) avg_review_delivered FROM analytics.fact_orders;

-- query_id: Q40
-- question: What is the latest review record per order?
-- business_purpose: Select one latest review with PostgreSQL DISTINCT ON.
-- grain: order
-- tables: core.order_reviews
-- techniques: DISTINCT ON
SELECT DISTINCT ON (order_id) order_id,review_id,review_score,review_creation_date FROM core.order_reviews ORDER BY order_id,review_creation_date DESC NULLS LAST,review_id DESC;

-- query_id: Q41
-- question: Which calendar months have no sales?
-- business_purpose: Generate a complete calendar and anti-join monthly revenue.
-- grain: month
-- tables: analytics.dim_date, analytics.fact_orders
-- techniques: generate_series, LEFT JOIN
WITH months AS (SELECT generate_series('2016-01-01'::date,'2018-12-01'::date,interval '1 month')::date AS month), sales AS (SELECT to_date((purchase_date_key/100)::text,'YYYYMM') AS month,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1) SELECT m.month,s.revenue FROM months m LEFT JOIN sales s USING(month) WHERE s.month IS NULL ORDER BY m.month;

-- query_id: Q42
-- question: Which categories have the broadest seller coverage?
-- business_purpose: Aggregate seller identities per category.
-- grain: category
-- tables: analytics.fact_order_items, analytics.dim_product
-- techniques: STRING_AGG, COUNT DISTINCT
SELECT p.product_category_name_english category,count(DISTINCT i.seller_key) seller_count,string_agg(DISTINCT i.seller_key,', ' ORDER BY i.seller_key) sellers FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1 ORDER BY seller_count DESC;
