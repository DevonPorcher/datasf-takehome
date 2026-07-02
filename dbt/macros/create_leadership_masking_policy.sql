{% macro create_leadership_masking_policy(column_name) %}
    {% set policy_name = target.database ~ '.' ~ generate_schema_name('analytics_finance', none) ~ '.leadership_masking_policy' %}
    {% set table_name = ref('employee_compensation') %}

    {% if execute %}
        {% set drop_sql %}
            EXECUTE IMMEDIATE $$
            BEGIN
                ALTER TABLE {{ table_name }} MODIFY COLUMN {{ column_name }} UNSET MASKING POLICY;
            EXCEPTION WHEN OTHER THEN
                NULL;
            END;
            $$;
        {% endset %}
        {% do run_query(drop_sql) %}
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
