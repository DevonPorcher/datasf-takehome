WITH

staging_compensation AS (
   SELECT * FROM {{ ref('stg_datasf__compensation') }}
),

compensation_aggregated_to_department AS (
    SELECT
        department_code,
        department,
        reporting_year,
        COUNT(*) AS employee_count,
        SUM(base_salary) AS total_base_salary,
        SUM(overtime) AS total_overtime,
        SUM(other_salary) AS total_other_salary,
        SUM(total_salary) AS total_overall_salary,
        AVG(base_salary) AS average_base_salary,
        AVG(overtime) AS average_overtime,
        AVG(other_salary) AS average_other_salary,
        AVG(total_salary) AS average_overall_salary
    FROM staging_compensation
    WHERE year_type='Fiscal'
    GROUP BY department_code, department, reporting_year
)

SELECT * FROM compensation_aggregated_to_department
