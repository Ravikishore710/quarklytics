# Metric definitions

## Revenue

- **Item revenue:** `SUM(price)` from order items.
- **Freight value:** `SUM(freight_value)` from order items.
- **Total order value:** `item_value + freight_value`.
- **GMV:** item price only in Q33, explicitly labeled `gmv`; it does not include freight.

## AOV

Average order value is `SUM(total_order_value) / COUNT(order_id)` over order-grain rows. It is not calculated from line rows unless they are first reduced to order grain. Q05 excludes null total values; the fact build produces zero item/freight totals for orders with no lines.

## Delivery

- `delivery_days`: elapsed days from purchase timestamp to delivered-customer timestamp, null when not delivered.
- `estimated_delivery_days`: date difference between estimated delivery date and purchase date.
- `is_late`: true only when both actual and estimated dates exist and actual delivery date is later than the estimate.

## Repeat customer

A repeat customer has more than one order when grouped by `customer_unique_id`. `customer_id` is deliberately not used for repeat-customer classification because it is an order-specific customer record identifier.

## Review score

Review averages include only rows with non-null review scores. Missing reviews are not treated as zero. Order-level review score is the average of available review scores for that order.
