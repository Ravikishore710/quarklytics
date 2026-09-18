# Data dictionary

## Core entities

| Table | Grain | Primary key | Notes |
|---|---|---|---|
| `core.customers` | source customer record | `customer_id` | `customer_unique_id` links records belonging to the same underlying customer |
| `core.orders` | one order | `order_id` | delivery timestamps are nullable |
| `core.order_items` | one line in one order | `(order_id, order_item_id)` | price and freight are numeric |
| `core.order_payments` | one payment sequence in one order | `(order_id, payment_sequential)` | an order may have multiple payments |
| `core.order_reviews` | one review identifier | `review_id` | do not assume one review per order |
| `core.products` | one product | `product_id` | category may be null |
| `core.sellers` | one seller | `seller_id` | seller location is source-reported |
| `core.geolocation` | one geographic observation | `geolocation_id` | ZIP prefix is not unique |
| `core.category_translation` | one source category | `product_category_name` | English translation may be null |

## Analytics entities

`dim_date` spans 2016-01-01 through 2018-12-31 and is generated in SQL. `dim_customer` is keyed by `customer_unique_id`. `fact_orders` is order-grain. `fact_order_items` is order-line-grain.
