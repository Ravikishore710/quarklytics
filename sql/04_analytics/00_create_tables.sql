DROP SCHEMA IF EXISTS analytics CASCADE;
CREATE SCHEMA analytics;
CREATE TABLE analytics.dim_date (
  date_key integer PRIMARY KEY, calendar_date date UNIQUE NOT NULL, year integer NOT NULL,
  quarter integer NOT NULL, month integer NOT NULL, month_name text NOT NULL, week integer NOT NULL,
  day integer NOT NULL, day_of_week integer NOT NULL, is_weekend boolean NOT NULL
);
CREATE TABLE analytics.dim_customer (
  customer_key text PRIMARY KEY, customer_unique_id text NOT NULL, first_customer_id text,
  customer_state char(2), customer_city text
);
CREATE TABLE analytics.dim_product (
  product_key text PRIMARY KEY, product_category_name text, product_category_name_english text
);
CREATE TABLE analytics.dim_seller (
  seller_key text PRIMARY KEY, seller_state char(2), seller_city text
);
CREATE TABLE analytics.fact_orders (
  order_id text PRIMARY KEY, customer_key text REFERENCES analytics.dim_customer(customer_key),
  purchase_date_key integer REFERENCES analytics.dim_date(date_key), order_status text,
  item_value numeric(14,2), freight_value numeric(14,2), total_order_value numeric(14,2),
  delivery_days numeric, estimated_delivery_days numeric, is_delivered boolean, is_late boolean,
  review_score numeric(4,2)
);
CREATE TABLE analytics.fact_order_items (
  order_id text, order_item_id integer, product_key text REFERENCES analytics.dim_product(product_key),
  seller_key text REFERENCES analytics.dim_seller(seller_key), purchase_date_key integer REFERENCES analytics.dim_date(date_key),
  price numeric(12,2), freight_value numeric(12,2), total_line_value numeric(12,2),
  PRIMARY KEY (order_id, order_item_id)
);
