DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;

CREATE TABLE core.customers (
  customer_id text PRIMARY KEY,
  customer_unique_id text NOT NULL,
  customer_zip_code_prefix integer,
  customer_city text,
  customer_state char(2)
);
CREATE TABLE core.orders (
  order_id text PRIMARY KEY,
  customer_id text NOT NULL REFERENCES core.customers(customer_id),
  order_status text NOT NULL,
  order_purchase_timestamp timestamptz NOT NULL,
  order_approved_at timestamptz,
  order_delivered_carrier_date timestamptz,
  order_delivered_customer_date timestamptz,
  order_estimated_delivery_date timestamptz
);
CREATE TABLE core.products (
  product_id text PRIMARY KEY,
  product_category_name text,
  product_name_length integer,
  product_description_length integer,
  product_photos_qty integer,
  product_weight_g numeric,
  product_length_cm numeric,
  product_height_cm numeric,
  product_width_cm numeric
);
CREATE TABLE core.sellers (
  seller_id text PRIMARY KEY,
  seller_zip_code_prefix integer,
  seller_city text,
  seller_state char(2)
);
CREATE TABLE core.order_items (
  order_id text REFERENCES core.orders(order_id),
  order_item_id integer,
  product_id text REFERENCES core.products(product_id),
  seller_id text REFERENCES core.sellers(seller_id),
  shipping_limit_date timestamptz,
  price numeric(12,2),
  freight_value numeric(12,2),
  PRIMARY KEY (order_id, order_item_id),
  CHECK (price IS NULL OR price >= 0),
  CHECK (freight_value IS NULL OR freight_value >= 0)
);
CREATE TABLE core.order_payments (
  order_id text REFERENCES core.orders(order_id),
  payment_sequential integer,
  payment_type text,
  payment_installments integer,
  payment_value numeric(12,2),
  PRIMARY KEY (order_id, payment_sequential),
  CHECK (payment_value IS NULL OR payment_value >= 0)
);
CREATE TABLE core.order_reviews (
  review_id text NOT NULL,
  order_id text REFERENCES core.orders(order_id),
  review_score smallint,
  review_comment_title text,
  review_comment_message text,
  review_creation_date timestamptz,
  review_answer_timestamp timestamptz,
  PRIMARY KEY (review_id, order_id),
  CHECK (review_score IS NULL OR review_score BETWEEN 1 AND 5)
);
CREATE TABLE core.geolocation (
  geolocation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  geolocation_zip_code_prefix integer,
  geolocation_lat double precision,
  geolocation_lng double precision,
  geolocation_city text,
  geolocation_state char(2)
);
CREATE TABLE core.category_translation (
  product_category_name text PRIMARY KEY,
  product_category_name_english text
);
