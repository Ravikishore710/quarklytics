# Indexing strategy

The project avoids indexing every column. Constraint-supporting indexes are created during core setup; workload-specific indexes are added only in `sql/06_indexes/02_optimized.sql` after a baseline has been captured.

Candidates were selected from benchmark and common join predicates: order purchase timestamp, order/customer links, order-item order/product/seller links, payment/review order links, customer state, and product category. The benchmark runner stores JSON plans so index use can be verified from evidence rather than assumed.

Run `ANALYZE` after bulk loading and after creating indexes. The native Olist dataset is large enough for useful planner experiments but not a basis for billion-row claims.
