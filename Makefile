.PHONY: up sample full test benchmark down
up:
	docker compose up -d postgres
sample: up
	python scripts/run_pipeline.py --sample
full: up
	python scripts/run_pipeline.py --full
test:
	pytest -q
benchmark:
	python scripts/benchmarks/run_benchmarks.py --runs 3
down:
	docker compose down
