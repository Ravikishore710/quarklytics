# ADR-003: Workload-driven indexes

**Decision:** Capture baseline plans before adding a small targeted index set.

**Reason:** Indexes have write, storage, and planner trade-offs. The project must show measured plan changes rather than blanket indexing.
