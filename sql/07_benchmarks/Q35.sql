-- benchmark_query: Q35
SELECT p.product_category_name_english category,sum(i.total_line_value) revenue FROM analytics.fact_order_items i JOIN analytics.dim_product p ON p.product_key=i.product_key GROUP BY 1 ORDER BY revenue DESC;
