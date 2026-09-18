# Query optimization protocol

Five representative queries are benchmarked: Q24, Q35, Q38, Q41, and Q42. For each query:

1. Run the baseline variant without workload-specific indexes.
2. Record `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`.
3. Create the targeted index set.
4. Run `ANALYZE`.
5. Run the same query again.
6. Compare planning time, execution time, actual rows, shared hit/read blocks, and plan nodes.
7. Compare live computation with materialized output where semantically equivalent.

The benchmark script repeats each query and writes one row per run. Hardware, PostgreSQL version, dataset size, cache conditions, and number of runs must accompany any conclusion. A measured improvement is required before writing a speedup claim.

## Measured benchmark results (Full Olist Dataset)

- **Database environment:** PostgreSQL 16.15 (Ubuntu 24.04 LTS x86_64), NVMe storage.
- **Dataset volume:** Full Olist dataset (99,441 orders, 112,650 order items, 32,951 products, 3,095 sellers).
- **Repetitions:** 5 runs per variant (median execution time reported).

| Query ID | Business Question / Focus | Baseline (ms) | Optimized (ms) | Materialized (ms) | Speedup (vs Baseline) | Buffer Reduction |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Q24** | Monthly rolling 3-month revenue | 25.341 ms | 24.842 ms | **0.386 ms** | **~65.6x** | 1,913 -> 16 blocks (99.2%) |
| **Q35** | Category revenue concentration | 68.390 ms | 71.932 ms | **0.462 ms** | **~148.0x** | 2,681 -> 16 blocks (99.4%) |
| **Q38** | Delivery percentiles (P50/P90) | 53.624 ms | 52.478 ms | N/A | ~2.1% | Identical (full scan required) |
| **Q41** | Calendar anti-join (zero-sales months) | 17.106 ms | 16.332 ms | N/A | ~4.5% | Identical (calendar hash join) |
| **Q42** | Seller coverage per category | 178.361 ms | 149.265 ms | N/A | **~16.3%** | 29.1 ms reduction |

### Key takeaways and trade-offs

1. **Materialized Views Deliver Order-of-Magnitude Gains for Reporting aggregates:**  
   Pre-aggregating item revenue by month and category (`analytics.mv_monthly_category_revenue`) dropped execution time from ~68 ms down to ~0.46 ms for Q35 (~148x speedup) and from ~25 ms to ~0.38 ms for Q24 (~65x speedup), while reducing shared buffer page hits by over 99.2%. The trade-off is the maintenance cost (`REFRESH MATERIALIZED VIEW` upon ingestion).
2. **Sequential Scans are Optimal for Global Analytics:**  
   For heavy percentile computations (`percentile_cont` in Q38) scanning 96,478 delivered orders, a sequential scan in PostgreSQL remains more efficient than index lookups because nearly the entire table must be sorted.
3. **Targeted Indexes Benefit Multi-way Relational Traversal:**  
   Targeted foreign-key and dimension indexes reduced Q42 runtime by 16.3% (from 178.36 ms to 149.26 ms). Selective indexes on timestamps and foreign keys keep writes lightweight while supporting specific filter and join operations.

