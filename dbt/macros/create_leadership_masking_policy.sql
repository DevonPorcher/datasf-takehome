{% macro create_leadership_masking_policy(column_name) %}
    {% set policy_name = target.database ~ '.' ~ generate_schema_name('analytics_finance', none) ~ '.leadership_masking_policy' %}
    {% set table_name = ref('employee_compensation') %}

    {% if execute %}
        {% set check_sql %}
            SELECT COUNT(*) AS cnt
            FROM {{ target.database }}.INFORMATION_SCHEMA.POLICY_REFERENCES
            WHERE REF_ENTITY_NAME = '{{ table_name.identifier }}'
            AND REF_COLUMN_NAME = '{{ column_name }}'
            AND POLICY_KIND = 'MASKING_POLICY'
        {% endset %}
        {% set results = run_query(check_sql) %}
        {% if results.rows[0][0] > 0 %}
            {% set drop_sql %}
                ALTER TABLE {{ table_name }} MODIFY COLUMN {{ column_name }} UNSET MASKING POLICY;
            {% endset %}
            {% do run_query(drop_sql) %}
        {% endif %}
    {% endif %}

    {% set create_sql %}
        CREATE OR REPLACE MASKING POLICY {{ policy_name }}
        AS (val VARCHAR) RETURNS VARCHAR ->
            CASE
                WHEN CURRENT_ROLE() = 'LEADERSHIP'
                    THEN ARRAY_TO_STRING(TRANSFORM(
                        SPLIT(val, ' '), x -> CONCAT(LEFT(x, 1), '***')
                    ), ' ')
                ELSE val
            END;
    {% endset %}
    {% do run_query(create_sql) %}

    {% set apply_sql %}
        ALTER TABLE {{ table_name }}
        MODIFY COLUMN {{ column_name }} SET MASKING POLICY {{ policy_name }};
    {% endset %}
    {% do run_query(apply_sql) %}
{% endmacro %}
