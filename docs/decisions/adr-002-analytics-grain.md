# ADR-002: Explicit fact grains

**Decision:** Keep an order-grain fact and a line-grain fact as separate tables.

**Reason:** Joining two facts at incompatible grains can multiply revenue. Explicit grains and pre-aggregation make query intent auditable.
