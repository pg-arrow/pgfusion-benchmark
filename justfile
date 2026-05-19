# pgfusion-benchmark justfile
# Usage: just <recipe>   (run from pgfusion-benchmark/)
# Requires: https://github.com/casey/just
# Requires: PG_HARNESS_DIR=/path/to/pg-test-harness

pg_version := env_var_or_default("PG_VERSION", "pg18")

# ── Default ───────────────────────────────────────────────────────────────────

[group('default')]
help:
    @just --list --unsorted

# ── Common ────────────────────────────────────────────────────────────────────

# Apply PostgreSQL performance tuning (parallelism, memory, JIT). Shared by all benchmarks.
[group('common')]
pg-tune pg=pg_version:
    bash tune_postgres.sh {{pg}}

# ── ClickBench ────────────────────────────────────────────────────────────────

# First-time setup: download hits dataset and load into PostgreSQL
[group('clickbench')]
clickbench-setup pg=pg_version:
    cd clickbench && bash setup.sh {{pg}}


# Run 43-query comparison (pgfusion vs PostgreSQL)
# Usage: just clickbench [pg_version] [runs] [query=N]
[group('clickbench')]
clickbench pg=pg_version runs="3" query="":
    cd clickbench && bash run.sh {{pg}} {{runs}} \
        $([ -n "{{query}}" ] && echo "--query={{query}}" || true)

# Run and save results to checkpoints/<short-hash>[-label]/
# Usage: just clickbench-checkpoint pg18 3 my-label
[group('clickbench')]
clickbench-checkpoint pg=pg_version runs="3" label="" query="":
    cd clickbench && bash run.sh {{pg}} {{runs}} --checkpoint \
        $([ -n "{{label}}" ] && echo "--label={{label}}" || true) \
        $([ -n "{{query}}" ] && echo "--query={{query}}" || true)

# Archive current results without re-running
[group('clickbench')]
clickbench-save label="":
    cd clickbench && bash run.sh --checkpoint-only \
        $([ -n "{{label}}" ] && echo "--label={{label}}" || true)

# Open the latest ClickBench heatmap in a browser
[group('clickbench')]
clickbench-report:
    open clickbench/checkpoints/current/heatmap.html

# Open a checkpointed heatmap by slug
[group('clickbench')]
clickbench-report-checkpoint slug:
    open clickbench/checkpoints/{{slug}}/heatmap.html

# ── TPC-H ─────────────────────────────────────────────────────────────────────

# First-time setup: generate data with dbgen and load into PostgreSQL
# Usage: just tpch-setup [pg_version] [scale_factor]
[group('tpch')]
tpch-setup pg=pg_version scale="10":
    cd tpch && bash setup.sh {{pg}} {{scale}}

# Run 22-query comparison (pgfusion vs PostgreSQL)
[group('tpch')]
tpch pg=pg_version runs="3":
    cd tpch && bash run.sh {{pg}} {{runs}}

# Run and save results to checkpoints/<short-hash>[-label]/
# Usage: just tpch-checkpoint pg18 3 my-label
[group('tpch')]
tpch-checkpoint pg=pg_version runs="3" label="":
    cd tpch && bash run.sh {{pg}} {{runs}} --checkpoint \
        $([ -n "{{label}}" ] && echo "--label={{label}}" || true)

# Archive current results without re-running
[group('tpch')]
tpch-save label="":
    cd tpch && bash run.sh --checkpoint-only \
        $([ -n "{{label}}" ] && echo "--label={{label}}" || true)

# Run a single TPC-H query by number
[group('tpch')]
tpch-query query pg=pg_version:
    cd tpch && bash run.sh {{pg}} --query={{query}}

# Run all TPC-H queries except the given one
[group('tpch')]
tpch-skip skip pg=pg_version runs="3":
    cd tpch && bash run.sh {{pg}} {{runs}} --skip={{skip}}

# Open the latest TPC-H heatmap in a browser
[group('tpch')]
tpch-report:
    open tpch/heatmap.html

# Open a checkpointed TPC-H heatmap by slug
[group('tpch')]
tpch-report-checkpoint slug:
    open tpch/checkpoints/{{slug}}/heatmap.html
