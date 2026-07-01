WITH

staging_compensation AS (
    SELECT * FROM {{ ref('stg_datasf__compensation') }}
),

department_name_agg AS (
    SELECT
        *,
       (
           LISTAGG(DISTINCT department, ' | ')
            WITHIN GROUP (ORDER BY department ASC)
            OVER (PARTITION BY department_code)
        ) AS department_agg
    FROM staging_compensation
),

compensation_aggregated_to_department AS (
    SELECT
        department_code,
        department_agg AS department,
        year_type,
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
    FROM department_name_agg
    WHERE department_code IS NOT NULL
    GROUP BY department_code, department_agg, year_type, reporting_year
)

SELECT * FROM compensation_aggregated_to_department
