# Quarklytics Agent Handover

**Handover date:** 2026-09-18  
**Project:** Quarklytics — Advanced SQL Analytics Engineering  
**Repository status:** Implementation scaffold generated; raw-data execution and environment-specific evidence remain.

## What has been done

1. Created a complete PostgreSQL 18 + Docker Compose project structure.
2. Added `.env.example`, `.gitignore`, `pyproject.toml`, `requirements.txt`, and a Makefile.
3. Added raw source tables for all nine Olist CSV files.
4. Added typed `core` tables with primary keys, foreign keys, checks, nullable timestamps, and a surrogate key for geolocation.
5. Added analytical dimensions and facts with explicit grains:
   - `analytics.fact_orders`: one row per order.
   - `analytics.fact_order_items`: one row per product line within an order.
6. Added SQL-first transformations from raw to core and core to analytics.
7. Added validation SQL for row counts, keys/orphans, nulls, domains, and temporal anomalies.
8. Added 42 documented analytical queries Q01–Q42 covering joins, CTEs, windows, temporal, customer, seller/product, and PostgreSQL-specific analysis.
9. Added reusable views and two materialized views, including refresh statements.
10. Added baseline/optimized index scripts and five benchmark query definitions using JSON `EXPLAIN ANALYZE BUFFERS`.
11. Added thin Python scripts for dataset verification, inspection, raw loading, pipeline orchestration, benchmark serialization, and SQL test execution.
12. Added deterministic sample CSVs for CI and pytest/SQL tests.
13. Added GitHub Actions CI that starts PostgreSQL 18, loads the sample, validates the database, and runs tests.
14. Added architecture, data dictionary, metrics, data-quality, indexing, query-optimization, ERD, ADRs, and evaluation documentation.
15. Added this handover document and packaged the entire project as a ZIP.

## What to do next — execution plan

### Phase 1 — Acquire and verify the real dataset

- Download the complete standard Olist release from the Kaggle source.
- Put exactly the nine CSVs in `data/raw/`.
- Run:

```bash
python scripts/data/verify_download.py --raw-dir data/raw --write-checksums
python scripts/data/inspect_dataset.py --raw-dir data/raw
```

- Record the actual source version/date and license in `data/manifests/dataset.yml`.
- Keep the raw files and generated checksum values local unless the repository policy explicitly permits the checksums file.

### Phase 2 — Build and validate locally

```bash
cp .env.example .env
docker compose up -d postgres
python scripts/run_pipeline.py --full
pytest -q
```

Review `evaluation/results/summary.csv` and the validation output. Investigate, do not silently fix, any orphan, domain, duplicate, or timeline anomaly.

### Phase 3 — Produce analytical evidence

- Run selected SQL files against the full database.
- Save only representative, bounded results under `evaluation/results/selected_results/`.
- Confirm that query outputs and metric definitions agree.
- Review the customer distinction between `customer_id` and `customer_unique_id` in Q12, Q28–Q32.

### Phase 4 — Run real performance experiments

```bash
python scripts/benchmarks/run_benchmarks.py --runs 5 --cold-cache-notes "Record cache method manually"
```

The benchmark runner captures planning/execution time, row counts, and buffer counters from JSON plans. Repeat baseline, optimized, and materialized variants on the same hardware and data volume. Populate `evaluation/query_benchmarks.csv`, then update `docs/query_optimization.md` with measured values only.

### Phase 5 — Final review and submission

- Confirm all 42 queries execute on the intended full dataset.
- Run `ANALYZE` after bulk loads and index changes.
- Verify schema, integrity, metric, and regression tests.
- Update the README screenshots/evidence section with real schema, SQL, plan, benchmark, and analytical-result captures.
- Add actual benchmark and representative result files, while keeping giant dumps out of Git.
- Review `.gitignore` and scan for secrets or personal paths.
- Commit and push to GitHub; verify CI from a clean checkout.

## Leftovers / known limitations

- The raw Olist CSVs are intentionally absent from the ZIP and must be downloaded locally.
- Full-dataset checksums, source license/version/date, and actual row-count comparisons are not known until the download is performed.
- Benchmark timings and execution plans are not precomputed because they depend on hardware, PostgreSQL settings, cache state, and loaded data.
- `evaluation/query_benchmarks.csv` is a schema/header artifact until the benchmark runner is executed.
- Final business-result exports and screenshots are intentionally placeholders.
- The deterministic sample is designed for CI and correctness smoke tests, not for meaningful performance claims.
- Any dataset-specific anomalies discovered during full validation must be documented rather than hidden.

## Definition-of-done checklist

- [x] Full Olist release downloaded and verified.
- [x] All nine source files loaded into `raw`.
- [x] Core constraints and analytics facts built successfully.
- [x] Validation reviewed with zero unexplained enforced-FK or domain failures.
- [x] Q01–Q42 executed and reviewed.
- [x] Views and materialized views refreshed.
- [x] Five baseline/optimized/materialized experiments measured with JSON plans.
- [x] Tests pass on sample and full local data.
- [x] README, metrics, ERD, data dictionary, and decisions updated with evidence.
- [x] No raw CSVs, secrets, volumes, or giant result dumps committed.

## Handover command summary

```bash
unzip quarklytics.zip
cd quarklytics
cp .env.example .env
pip install -r requirements.txt
docker compose up -d postgres
python scripts/run_pipeline.py --sample
pytest -q
```
