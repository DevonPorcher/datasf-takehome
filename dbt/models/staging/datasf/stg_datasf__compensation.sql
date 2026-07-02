{{ config(
    materialized='incremental',
    unique_key=['employee_name', 'job', 'reporting_year', 'year_type'],
    incremental_strategy='merge'
) }}

WITH

raw_compensation AS (
    SELECT * FROM {{ source('raw', 'raw_datasf__compensation') }}
),

staging_compensation AS (
    SELECT
        "Organization Group Code"::NUMBER(2,0) AS organization_group_code,
        "Job Family Code"::VARCHAR(32) AS job_family_code,
        "Job Code"::VARCHAR(32) AS job_code,
        "Year Type"::VARCHAR(16) AS year_type,
        "Year"::NUMBER(4,0) AS reporting_year,
        "Organization Group"::VARCHAR(128) AS organization_group,
        "Department Code"::VARCHAR(3) AS department_code,
        "Department"::VARCHAR(128) AS department,
        "Union Code"::NUMBER(3,0) AS union_code,
        "Union"::VARCHAR(128) AS union_name,
        "Job Family"::VARCHAR(128) AS job_family,
        "Job"::VARCHAR(128) AS job,
        "Employee Name"::VARCHAR(256) AS employee_name,
        REPLACE("Salaries", ',', '')::NUMBER(10,2) AS base_salary,
        REPLACE("Overtime", ',', '')::NUMBER(10,2) AS overtime,
        REPLACE("Other Salaries", ',', '')::NUMBER(10,2) AS other_salary,
        REPLACE("Total Salary", ',', '')::NUMBER(10,2) AS total_salary,
        REPLACE("Retirement", ',', '')::NUMBER(10,2) AS retirement,
        REPLACE("Health and Dental", ',', '')::NUMBER(10,2) AS health_and_dental,
        REPLACE("Other Benefits", ',', '')::NUMBER(10,2) AS other_benefits,
        REPLACE("Total Benefits", ',', '')::NUMBER(10,2) AS total_benefits,
        REPLACE("Total Compensation", ',', '')::NUMBER(10,2) AS total_compensation,
        REPLACE("Hours", ',', '')::NUMBER(6,2) AS hours,
        "Employment Type"::VARCHAR(64) AS employment_type,
        TO_TIMESTAMP_NTZ("data_as_of", 'YYYY MON D HH12:MI:SS AM')::TIMESTAMP_NTZ AS data_as_of,
        TO_TIMESTAMP_NTZ("data_loaded_at", 'YYYY/MM/DD HH12:MI:SS AM')::TIMESTAMP_NTZ AS data_loaded_at,
        TO_TIMESTAMP_NTZ("created_at"/1000000)::TIMESTAMP_NTZ AS created_at
    FROM raw_compensation
)

SELECT * FROM staging_compensation

WHERE employee_name IS NOT NULL
    AND job_code IS NOT NULL
    AND reporting_year IS NOT NULL
    AND year_type IS NOT NULL
    AND department_code IS NOT NULL

{% if is_incremental() %}
    -- Select only rows created or updated after the last recorded update
    AND created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
