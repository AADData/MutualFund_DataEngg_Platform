# Implementation Roadmap

## Phase 1 - Source System

Deliverables:

- Azure SQL schema.
- Seed data generator.
- Source data quality queries.
- ERD screenshot for portfolio.

Practice focus:

- Relational modelling.
- Primary keys and foreign keys.
- Transactional constraints.
- SQL performance basics.

## Phase 2 - Bronze Delta

Deliverables:

- Databricks notebook or workflow for each source table.
- Bronze Delta tables with ingestion metadata.
- Replayable batch ingestion.

Practice focus:

- Delta table creation.
- Schema enforcement.
- Raw landing pattern.
- Batch IDs and audit metadata.

## Phase 3 - Silver Delta

Deliverables:

- Silver tables for each functional entity.
- Deduplication using business keys and update timestamps.
- Data quality quarantine table.
- Change Data Feed enabled on selected tables.

Practice focus:

- `MERGE INTO`.
- Delta constraints.
- Generated columns.
- Change Data Feed.
- Data quality rules.

## Phase 4 - Gold Delta

Deliverables:

- Daily and monthly aggregates.
- Holdings valuation tables.
- Commission calculation tables.
- Reconciliation summary.

Practice focus:

- Business logic implementation.
- Time travel checks.
- Optimize and vacuum.
- Dashboard serving tables.

## Phase 5 - DBT

Deliverables:

- DBT sources over Silver/Gold.
- Staging models.
- Dimensions and facts.
- Tests and documentation.
- Optional snapshots for slowly changing dimensions.

Practice focus:

- DBT model layers.
- Generic tests.
- Custom tests.
- Docs and lineage.
- Incremental models.

## Phase 6 - Dashboard

Deliverables:

- Agent commission page.
- Investor holding page.
- Fund investment page.
- Data quality page.

Practice focus:

- KPI design.
- Dashboard query performance.
- Business-friendly filters.
- Portfolio demonstration.

## Phase 7 - AADData.com

Deliverables:

- Bio page.
- Project case study page.
- Dashboard link.
- Architecture visual.
- Certification learning notes.

Practice focus:

- Technical storytelling.
- CV alignment.
- Public proof of capability.

## Recommended Weekly Plan

| Week | Focus | Outcome |
| --- | --- | --- |
| 1 | Azure SQL model and seed data | Source database ready |
| 2 | Bronze ingestion | Raw Delta lake ready |
| 3 | Silver data quality and merges | Conformed lakehouse layer |
| 4 | Gold metrics | Dashboard-ready tables |
| 5 | DBT marts and tests | Facts, dimensions, docs |
| 6 | Dashboard | Working analytics app |
| 7 | AADData.com | Public portfolio story |
| 8 | Polish and certification mapping | Demo-ready project |

