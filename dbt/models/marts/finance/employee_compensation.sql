WITH

staging_compensation AS (
   SELECT * FROM {{ ref('stg_datasf__compensation') }}
),

employee_compensation AS (
    SELECT
        employee_name,
        organization_group_code,
        job_family_code,
        job_code,
        year_type,
        reporting_year,
        organization_group,
        department_code,
        department,
        union_code,
        union_name,
        job_family,
        job,
        base_salary,
        overtime,
        other_salary,
        total_salary,
        IFF(base_salary > 0, overtime/base_salary, 0) AS overtime_to_base_salary_ratio,
        overtime_to_base_salary_ratio > 0.5625 AS high_overtime,
        retirement,
        health_and_dental,
        other_benefits,
        total_benefits,
        total_compensation,
        hours,
        employment_type,
        data_as_of,
        data_loaded_at,
        created_at
    FROM staging_compensation
)

SELECT * FROM employee_compensation
