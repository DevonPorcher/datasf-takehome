WITH

department_compensation AS (
   SELECT * FROM {{ ref('department_compensation') }}
),

department_role_mapping AS (
    SELECT DISTINCT
        CONCAT(department_code, '_DEPARTMENT_HEAD') AS role_name,
        department_code
    FROM department_compensation
)

SELECT * FROM department_role_mapping
