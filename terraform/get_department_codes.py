#!/usr/bin/env python3

from dotenv import load_dotenv
import json
import sys
import os
import snowflake.connector


dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(dotenv_path)


def main():
    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        password=os.getenv('SNOWFLAKE_PASSWORD'),
        role=os.getenv('SNOWFLAKE_ROLE'),
        warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
        database=os.getenv('SNOWFLAKE_DATABASE'),
        schema=os.getenv('SNOWFLAKE_ANALYTICS_SCHEMA'),
    )

    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT DISTINCT department_code
            FROM department_head_role_mapping;
        """)
        department_codes = [row[0] for row in cur.fetchall()]
    finally:
        cur.close()
        conn.close()

    # sys.stdout.write(json.dumps(department_codes))
    print(json.dumps({"department_codes": json.dumps(department_codes)}))


if __name__ == "__main__":
    main()
