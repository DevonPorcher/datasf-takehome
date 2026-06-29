WITH

int_department_compensation AS (
   SELECT * FROM {{ ref('int_compensation_aggregated_to_department') }}
),

department_compensation AS (
    SELECT
        department_code,
        department,
        reporting_year,
        total_base_salary,
        total_overtime,
        average_base_salary,
        average_overtime,
        total_overtime/total_base_salary AS overtime_to_base_salary_ratio
    FROM int_department_compensation
)

SELECT * FROM department_compensation
