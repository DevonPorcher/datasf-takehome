{% macro create_department_head_row_access_policy() %}
    {% set policy_name = target.database ~ '.' ~ generate_schema_name('analytics_finance', none) ~ '.department_row_access_policy' %}
    {% set table_name = ref('employee_compensation') %}

    {% set drop_sql %}
        ALTER TABLE {{ table_name }} DROP ALL ROW ACCESS POLICIES;
    {% endset %}
    {% do run_query(drop_sql) %}

    {% set create_sql %}
        CREATE OR REPLACE ROW ACCESS POLICY {{ policy_name }}
        AS (current_department_code VARCHAR) RETURNS BOOLEAN ->
            CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'LEADERSHIP')
            OR EXISTS (
                SELECT 1 FROM {{ ref('department_head_role_mapping') }}
                WHERE role_name = CURRENT_ROLE()
                AND department_code = current_department_code
            );
    {% endset %}
    {% do run_query(create_sql) %}

    {% set apply_sql %}
        ALTER TABLE {{ table_name }}
        ADD ROW ACCESS POLICY {{ policy_name }}
        ON (department_code);
    {% endset %}
    {% do run_query(apply_sql) %}
{% endmacro %}
