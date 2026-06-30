#!/usr/bin/env python3

import argparse
from datetime import datetime
from dotenv import load_dotenv
import os
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas


dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(dotenv_path)


def ingest_local_file_to_snowflake(
    file: str,
    table_name: str,
    verbose: bool = False,
) -> None:
    df = pd.read_csv(file, low_memory=False)
    df['created_at'] = pd.Timestamp.now()

    conn = snowflake.connector.connect(
        account=os.getenv('SNOWFLAKE_ACCOUNT'),
        user=os.getenv('SNOWFLAKE_USER'),
        password=os.getenv('SNOWFLAKE_PASSWORD'),
        role=os.getenv('SNOWFLAKE_ROLE'),
        warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
        database=os.getenv('SNOWFLAKE_DATABASE'),
        schema=os.getenv('SNOWFLAKE_RAW_SCHEMA'),
    )

    _, _, nrows, raw_output = write_pandas(
        conn,
        df=df,
        table_name=table_name,
        auto_create_table=True,
        overwrite=True,
        table_type='transient',
    )
    conn.close()

    print('{} rows created'.format(nrows))
    if verbose:
        print('Snowflake raw output: {}'.format(raw_output))


def parse_arguments():
    parser = argparse.ArgumentParser(description='ingest raw data')
    parser.add_argument('-input_file', help='input file path')
    parser.add_argument('-table_name', help='snowflake table name')
    parser.add_argument(
        '-v',
        '--verbose',
        action='store_true',
        help='printout verbosity',
    )
    args = parser.parse_args()
    return args


def main():
    start_time = datetime.now()

    args = parse_arguments()
    print('Loading {} to table {}'.format(args.input_file, args.table_name))
    # For this project, table_name should always be raw_datasf_compensation
    ingest_local_file_to_snowflake(
        file=args.input_file,
        table_name=args.table_name,
        verbose=args.verbose,
    )

    print('ingest raw datasf file runtime: {}'.format(
        datetime.now() - start_time)
    )


if __name__ == '__main__':
    main()
