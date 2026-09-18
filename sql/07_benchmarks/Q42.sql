-- benchmark_query: Q42
SELECT p.product_category_name_english,count(DISTINCT i.seller_key) FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1;
