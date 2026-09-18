DROP MATERIALIZED VIEW IF EXISTS analytics.mv_monthly_category_revenue;
CREATE MATERIALIZED VIEW analytics.mv_monthly_category_revenue AS
SELECT f.purchase_date_key / 100 month_key, p.product_category_name_english category,
       sum(f.total_line_value) total_revenue, count(DISTINCT f.order_id) order_count
FROM analytics.fact_order_items f JOIN analytics.dim_product p ON p.product_key=f.product_key
GROUP BY 1,2;
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_monthly_category_revenue ON analytics.mv_monthly_category_revenue(month_key, category);

DROP MATERIALIZED VIEW IF EXISTS analytics.mv_seller_monthly_performance;
CREATE MATERIALIZED VIEW analytics.mv_seller_monthly_performance AS
SELECT f.purchase_date_key / 100 month_key, f.seller_key, sum(f.total_line_value) total_line_value,
       count(DISTINCT f.order_id) order_count
FROM analytics.fact_order_items f GROUP BY 1,2;
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_seller_monthly_performance ON analytics.mv_seller_monthly_performance(month_key, seller_key);

-- Refresh after a full rebuild or source refresh:
-- REFRESH MATERIALIZED VIEW analytics.mv_monthly_category_revenue;
-- REFRESH MATERIALIZED VIEW analytics.mv_seller_monthly_performance;
