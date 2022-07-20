import json
import sys

from devtools import debug
from psycopg2 import connect

from config import get_config
from sql import format_sql


def handle(event: dict, context) -> dict:
    """
    Grants or revokes a Postgres role for the requesting Sym user.

    For more details on the event object format, refer to our reporting docs:
    https://docs.symops.com/docs/reporting
    """
    print("Got event:")
    print(json.dumps(event))

    try:
        username = resolve_user(event)
        body = update_user(username, event)
        return {"body": body, "errors": []}
    except Exception as e:
        return {"body": {}, "errors": [str(e).rstrip()]}


def resolve_user(event: dict) -> str:
    """
    Convert the incoming username, which is an email address, into a database username. Our starter
    implementation creates the database username by using the email subject and then substituting
    hyphens with underscores.
    """
    email = event["run"]["actors"]["request"]["username"]
    username = email.split("@")[0]
    return username.replace("-", "_")


def update_user(username: str, event: dict) -> dict:
    """
    Grant or revoke the target role for the given user name
    """
    stmt = format_sql(username, event, config)
    with conn:
        with conn.cursor() as curs:
            curs.execute(stmt)
    return {"username": username}


# Get the DB connection outside of the handler so that it can be reused for better performance.
try:
    config = get_config()
    conn = connect(
        host=config.pg_host,
        port=config.pg_port,
        user=config.pg_user,
        password=config.pg_pass,
    )
except Exception as e:
    print("ERROR: Unexpected error: Could not connect to DB")
    print(e)
    sys.exit()


def load_event():
    """Load json from stdin"""
    if not sys.stdin.isatty():
        lines = sys.stdin.readlines()
        data = " ".join(lines)
        return json.loads(data)
    raise RuntimeError("Please supply a json payload via stdin")


# Allows local testing using an example json payload from the ../test directory
if __name__ == "__main__":
    event = load_event()
    result = handle(event, {})
    debug(result)
