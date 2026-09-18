-- Baseline phase: intentionally avoid adding workload-specific indexes. Existing
-- relational indexes support constraints; capture baseline plans before 02_optimized.sql.
ANALYZE;
