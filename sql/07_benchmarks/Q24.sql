-- benchmark_query: Q24
SELECT purchase_date_key/100 month_key,sum(total_order_value) revenue FROM analytics.fact_orders GROUP BY 1 ORDER BY 1;
