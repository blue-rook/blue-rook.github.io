+++
title = "Building a Lightweight Data Quality Checker with Polars"
date = "2026-02-12T12:00:00-03:00"
draft = false
description = "A walkthrough of data-quality-checker — a focused Python library for validating Polars DataFrames with built-in SQLite logging and a YAML-driven CLI."
tags = ["python", "polars", "data-quality", "data-engineering", "open-source"]
categories = ["engineering"]
authors = ["Blue Rook Technology"]
showMetadata = true
+++

Data quality is one of those problems that every data team hits eventually. Bad data sneaks in, pipelines produce wrong numbers, and stakeholders lose trust. The usual response is to reach for a heavyweight framework — but sometimes you just need something simple that does the job without pulling in half the ecosystem.

That is why we built [**data-quality-checker**](https://github.com/pedrogasparotti/data-quality-checker): a focused Python library for validating Polars DataFrames with automatic SQLite logging and a clean CLI.

## The problem

Most data quality tools fall into two camps: enterprise platforms that require significant setup and operational overhead, or ad-hoc scripts scattered across notebooks that nobody maintains. We wanted something in between — a library you can `pip install`, point at your data, and get clear pass/fail results with a persistent audit trail.

## Design principles

We kept three constraints in mind:

1. **Stay small.** The core library is under 400 lines of Python. No dependency bloat, no plugin system, no configuration DSL.
2. **Use Polars.** Polars' vectorized operations make validation fast without writing low-level code. If your data fits in memory (< 100GB), this approach scales well.
3. **Log everything.** Every check result is automatically stored in SQLite with a timestamp and context. You should never have to wonder "did we validate this data?"

## What it checks

The library ships with four validation checks that cover the most common data quality issues:

### Column uniqueness

```python
checker.is_column_unique(df, "order_id")
```

Detects duplicate values in a column — essential for primary keys and identifiers.

### Not-null validation

```python
checker.is_column_not_null(df, "customer_email")
```

Ensures no missing values in mandatory fields. Catches silent nulls before they propagate downstream.

### Accepted values

```python
checker.is_column_enum(df, "status", ["active", "inactive", "pending"])
```

Validates that categorical columns only contain expected values. Catches typos, encoding issues, and upstream schema changes.

### Referential integrity

```python
checker.are_tables_referential_integral(
    parent_df, "id",
    child_df, "parent_id"
)
```

Verifies foreign key relationships between two DataFrames. Prevents orphaned records from slipping through joins.

## Architecture

The design follows a clean separation of concerns:

```
DataQualityChecker        →  Validation logic
        │
        ▼
   DBConnector            →  SQLite persistence
        │
        ▼
   validation_log table   →  Timestamped results + JSON metadata
```

The `DataQualityChecker` class accepts a `DBConnector` via dependency injection. This makes testing straightforward — mock the database layer and test validation logic in isolation. In production, every check call automatically logs its result:

```python
from data_quality_checker import DataQualityChecker
from data_quality_checker.connector import DBConnector

db = DBConnector("validation_logs.db")
checker = DataQualityChecker(db)

result = checker.is_column_unique(df, "user_id")
# Returns True/False AND logs to SQLite automatically
```

Results are stored with ISO 8601 timestamps and optional JSON metadata, making it easy to query validation history with plain SQL.

## CLI interface

For pipeline integration, there is a command-line interface driven by YAML configuration:

```yaml
# checks.yml
db: validation_logs.db

checks:
  - type: not_null
    column: customer_email

  - type: unique
    column: order_id

  - type: accepted_values
    column: status
    values:
      - active
      - inactive
      - pending
```

Run it against a CSV or Parquet file:

```bash
dqc check data.parquet --config checks.yml
```

The CLI prints a formatted results table to stdout and logs everything to SQLite. Exit code 0 means all checks passed; exit code 1 means at least one failed — so it plugs directly into CI/CD pipelines and orchestrators.

You can also query the log history:

```bash
dqc logs validation_logs.db
```

## Testing

The project maintains 100% test coverage with 31 unit tests covering:

- Happy paths (valid data passes)
- Failure cases (invalid data fails correctly)
- Edge cases (empty DataFrames, all-null columns)
- Error handling (missing columns raise `ValueError`)
- Log verification (results actually persist to SQLite)

We use pytest with mock fixtures to isolate the validation layer from the database layer, plus integration tests that exercise the full stack with real SQLite databases.

## Trade-offs

This tool is deliberately constrained:

- **In-memory only** — if your dataset does not fit in RAM, you need a distributed solution.
- **Polars only** — no Pandas compatibility layer. We think Polars is the better tool and chose not to abstract over both.
- **SQLite only** — simple, embedded, no server to manage. For teams that need centralized logging, SQLite can be swapped out later.
- **Four checks** — we ship what we use. Custom validation rules can be added by extending the `DataQualityChecker` class.

## Getting started

```bash
pip install data-quality-checker-pg
```

```python
import polars as pl
from data_quality_checker import DataQualityChecker
from data_quality_checker.connector import DBConnector

db = DBConnector("my_checks.db")
checker = DataQualityChecker(db)

df = pl.read_csv("orders.csv")

checker.is_column_not_null(df, "order_id")
checker.is_column_unique(df, "order_id")
checker.is_column_enum(df, "status", ["placed", "shipped", "delivered"])
```

The project is open source under the MIT license. Check out the [repository on GitHub](https://github.com/pedrogasparotti/data-quality-checker), open an issue, or submit a PR. We are actively developing it and welcome contributions.
