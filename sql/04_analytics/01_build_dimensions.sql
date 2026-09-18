INSERT INTO analytics.dim_date
SELECT to_char(d, 'YYYYMMDD')::integer, d::date, extract(year from d)::integer,
       extract(quarter from d)::integer, extract(month from d)::integer, to_char(d, 'FMMonth'),
       extract(week from d)::integer, extract(day from d)::integer,
       extract(isodow from d)::integer, extract(isodow from d) IN (6, 7)
FROM generate_series('2016-01-01'::date, '2018-12-31'::date, interval '1 day') AS g(d);

INSERT INTO analytics.dim_customer
SELECT customer_unique_id, customer_unique_id, min(customer_id), min(customer_state), min(customer_city)
FROM core.customers GROUP BY customer_unique_id;
INSERT INTO analytics.dim_product
SELECT p.product_id, p.product_category_name, t.product_category_name_english
FROM core.products p LEFT JOIN core.category_translation t USING(product_category_name);
INSERT INTO analytics.dim_seller
SELECT seller_id, seller_state, seller_city FROM core.sellers;
