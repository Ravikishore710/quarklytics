# ADR-001: PostgreSQL 18 as the analytical database

**Decision:** Use PostgreSQL 18.x in Docker.

**Reason:** It provides typed relational modeling, mature analytical SQL, window functions, `generate_series`, `FILTER`, `DISTINCT ON`, percentile aggregates, planner statistics, JSON execution plans, and reproducible local setup.
