from psycopg2 import sql

from config import Config


def format_sql(username: str, event: dict, config: Config) -> sql.Composable:
    """
    Get the right sql statement for the supplied event and user
    """
    target_role = resolve_role(event)
    event_type = event["event"]["type"]
    if event_type == "escalate":
        return format_grant(target_role, username)
    elif event_type == "deescalate":
        return format_revoke(target_role, username)
    else:
        raise RuntimeError(f"Unsupported event type: {event_type}")


def resolve_role(event: dict) -> str:
    """Get the role name from the target name"""
    full_name = event["fields"]["target"]["name"]
    return full_name.split("-")[-1]


def format_grant(rolename: str, username: str) -> sql.Composable:
    """
    Use SQL Composition to safely generate a grant statement
    https://www.psycopg.org/docs/sql.html#module-psycopg2.sql
    """
    return sql.SQL(
        """
        GRANT
            {rolename}
        TO
            {username}
    """
    ).format(
        rolename=sql.Identifier(rolename),
        username=sql.Identifier(username),
    )


def format_revoke(rolename: str, username: str) -> sql.Composable:
    """
    Use SQL Composition to safely generate a revoke statement
    https://www.psycopg.org/docs/sql.html#module-psycopg2.sql
    """
    return sql.SQL(
        """
        REVOKE
            {rolename}
        FROM
            {username}
    """
    ).format(
        rolename=sql.Identifier(rolename),
        username=sql.Identifier(username),
    )
