-- benchmark_query: Q38
SELECT percentile_cont(.5) WITHIN GROUP(ORDER BY delivery_days),percentile_cont(.9) WITHIN GROUP(ORDER BY delivery_days) FROM analytics.fact_orders WHERE is_delivered;
