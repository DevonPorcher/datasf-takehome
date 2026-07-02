# DataSF Employee Compensation Pipeline

A secure, scalable data pipeline for ingesting and governing San Francisco employee compensation data, built with Snowflake, dbt, and Terraform.

## Pipeline Overview

Raw employee compensation data is loaded into Snowflake via a Python script, then transformed through a layered dbt project into analytics-ready tables. Access to those tables is governed by Snowflake RBAC, with roles managed by Terraform and row/column policies managed by dbt.

```
CSV → Raw → Staging → Intermediate → Marts
                  (managed by dbt)
```

The pipeline is designed to run daily, triggered by a cron job or Airflow DAG.

## Data Layers

**Raw** — Data is loaded as-is from the source CSV into Snowflake with no modifications. The load script adds a `created_at` ingestion timestamp to each row.

**Staging** — Raw data is cleaned and typed: dollar amounts are stripped of formatting, timestamps are parsed, and column names are normalized. Rows missing critical identifying fields (`employee_name`, `job_code`, `year_type`, `reporting_year`) are filtered out here before reaching any downstream models.

**Intermediate** — Staging data is aggregated by `department_code`, `year_type`, and `reporting_year` to produce per-department compensation totals and averages. Department codes with multiple names in the source data are handled by concatenating the names.

**Marts** — Two final tables consumed by downstream users:
- `department_compensation` — Department-level salary and overtime aggregates, including an overtime-to-base-salary ratio. Intended for public consumption.
- `employee_compensation` — Individual employee records with overtime anomaly flags. An employee is flagged if their overtime-to-base-salary ratio exceeds 0.5625, which corresponds to an average of 55+ hour work weeks (assuming 1.5x overtime pay).

## Access Control

Access is governed by Snowflake RBAC with three consumer tiers:

| Role | Table | Access |
|---|---|---|
| PUBLIC | `department_compensation` | Aggregated dept data, no individual records |
| LEADERSHIP | `employee_compensation` | All rows, but `employee_name` is masked (e.g. `J*** D***`) |
| `<DEPT>_DEPARTMENT_HEAD` | `employee_compensation` | Unmasked records, own department only |

**Terraform** creates and manages all roles and table-level grants.

**dbt** manages the policies applied to `employee_compensation` at the end of each run via `on-run-end` hooks:
- A row access policy restricts department head roles to rows matching their department code.
- A masking policy masks `employee_name` for the LEADERSHIP role.

Policies are reapplied on every dbt run because `CREATE OR REPLACE TABLE` drops attached policies. Terraform handles role structure; dbt handles data-level enforcement.

## CI/CD

GitHub Actions workflows run on pull requests:
- **dbt** — runs `dbt build` (models + tests) against an isolated `CI` schema in Snowflake when `dbt/**` is changed.
- **Terraform** — runs `terraform plan` when `terraform/**` is changed.

Status checks are required to pass before merging to `main`.

## Repository Structure

```
dbt/                  # dbt project (transformations, tests, policies)
terraform/            # Snowflake roles and grants
scripts/              # Data ingestion script
.github/workflows/    # CI/CD
```
