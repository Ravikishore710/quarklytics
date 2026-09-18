TRUNCATE core.order_items, core.order_payments, core.order_reviews, core.orders,
         core.products, core.sellers, core.geolocation, core.category_translation,
         core.customers RESTART IDENTITY CASCADE;

INSERT INTO core.customers
SELECT NULLIF(trim(customer_id), ''), NULLIF(trim(customer_unique_id), ''),
       NULLIF(trim(customer_zip_code_prefix), '')::integer,
       NULLIF(trim(customer_city), ''), NULLIF(trim(customer_state), '')::char(2)
FROM raw.customers WHERE NULLIF(trim(customer_id), '') IS NOT NULL;

INSERT INTO core.products
SELECT NULLIF(trim(product_id), ''), NULLIF(trim(product_category_name), ''),
       NULLIF(trim(product_name_lenght), '')::integer,
       NULLIF(trim(product_description_lenght), '')::integer,
       NULLIF(trim(product_photos_qty), '')::integer,
       NULLIF(trim(product_weight_g), '')::numeric,
       NULLIF(trim(product_length_cm), '')::numeric,
       NULLIF(trim(product_height_cm), '')::numeric,
       NULLIF(trim(product_width_cm), '')::numeric
FROM raw.products WHERE NULLIF(trim(product_id), '') IS NOT NULL;

INSERT INTO core.sellers
SELECT NULLIF(trim(seller_id), ''), NULLIF(trim(seller_zip_code_prefix), '')::integer,
       NULLIF(trim(seller_city), ''), NULLIF(trim(seller_state), '')::char(2)
FROM raw.sellers WHERE NULLIF(trim(seller_id), '') IS NOT NULL;

INSERT INTO core.orders
SELECT NULLIF(trim(order_id), ''), NULLIF(trim(customer_id), ''),
       NULLIF(trim(order_status), ''),
       NULLIF(trim(order_purchase_timestamp), '')::timestamptz,
       NULLIF(trim(order_approved_at), '')::timestamptz,
       NULLIF(trim(order_delivered_carrier_date), '')::timestamptz,
       NULLIF(trim(order_delivered_customer_date), '')::timestamptz,
       NULLIF(trim(order_estimated_delivery_date), '')::timestamptz
FROM raw.orders WHERE NULLIF(trim(order_id), '') IS NOT NULL;

INSERT INTO core.order_items
SELECT NULLIF(trim(order_id), ''), NULLIF(trim(order_item_id), '')::integer,
       NULLIF(trim(product_id), ''), NULLIF(trim(seller_id), ''),
       NULLIF(trim(shipping_limit_date), '')::timestamptz,
       NULLIF(trim(price), '')::numeric(12,2), NULLIF(trim(freight_value), '')::numeric(12,2)
FROM raw.order_items;

INSERT INTO core.order_payments
SELECT NULLIF(trim(order_id), ''), NULLIF(trim(payment_sequential), '')::integer,
       NULLIF(trim(payment_type), ''), NULLIF(trim(payment_installments), '')::integer,
       NULLIF(trim(payment_value), '')::numeric(12,2)
FROM raw.order_payments;

INSERT INTO core.order_reviews
SELECT NULLIF(trim(review_id), ''), NULLIF(trim(order_id), ''),
       NULLIF(trim(review_score), '')::smallint,
       NULLIF(trim(review_comment_title), ''), NULLIF(trim(review_comment_message), ''),
       NULLIF(trim(review_creation_date), '')::timestamptz,
       NULLIF(trim(review_answer_timestamp), '')::timestamptz
FROM raw.order_reviews;

INSERT INTO core.geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
SELECT NULLIF(trim(geolocation_zip_code_prefix), '')::integer,
       NULLIF(trim(geolocation_lat), '')::double precision,
       NULLIF(trim(geolocation_lng), '')::double precision,
       NULLIF(trim(geolocation_city), ''), NULLIF(trim(geolocation_state), '')::char(2)
FROM raw.geolocation;

INSERT INTO core.category_translation
SELECT NULLIF(trim(product_category_name), ''), NULLIF(trim(product_category_name_english), '')
FROM raw.category_translation;
