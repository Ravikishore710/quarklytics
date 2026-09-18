WITH item_totals AS (
  SELECT order_id, sum(price) AS item_value, sum(freight_value) AS freight_value
  FROM core.order_items GROUP BY order_id
), review_totals AS (
  SELECT order_id, avg(review_score::numeric) AS review_score
  FROM core.order_reviews GROUP BY order_id
)
INSERT INTO analytics.fact_orders
SELECT o.order_id, c.customer_unique_id,
       to_char(o.order_purchase_timestamp::date, 'YYYYMMDD')::integer,
       o.order_status, coalesce(i.item_value, 0), coalesce(i.freight_value, 0),
       coalesce(i.item_value, 0) + coalesce(i.freight_value, 0),
       CASE WHEN o.order_delivered_customer_date IS NOT NULL THEN extract(epoch FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400 END,
       CASE WHEN o.order_estimated_delivery_date IS NOT NULL THEN (o.order_estimated_delivery_date::date - o.order_purchase_timestamp::date) END,
       o.order_delivered_customer_date IS NOT NULL,
       CASE WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
            THEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date ELSE NULL END,
       r.review_score
FROM core.orders o JOIN core.customers c USING(customer_id)
LEFT JOIN item_totals i USING(order_id) LEFT JOIN review_totals r USING(order_id);

INSERT INTO analytics.fact_order_items
SELECT i.order_id, i.order_item_id, i.product_id, i.seller_id,
       to_char(o.order_purchase_timestamp::date, 'YYYYMMDD')::integer,
       i.price, i.freight_value, coalesce(i.price, 0) + coalesce(i.freight_value, 0)
FROM core.order_items i JOIN core.orders o USING(order_id);
