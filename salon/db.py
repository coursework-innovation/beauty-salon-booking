from contextlib import contextmanager

import psycopg2


@contextmanager
def transaction():
    connection = psycopg2.connect()
    try:
        with connection:
            yield connection
    finally:
        connection.close()


def fetch_one(sql, params=()):
    with transaction() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchone()
