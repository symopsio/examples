import hashlib
import logging
import re
import sys

import botocore
import pymysql
from config import Config, get_config
from devtools import debug
from sym.sdk.resource import SRN
from user_manager import UserEvent, UserManager

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def handle(event: dict, context) -> dict:
    """
    Creates or drops a MySQL user for the given request.
    """
    logger.debug("Got event: %s", event)

    try:
        user_event = resolve_event(config, event)
        if user_event.event_type == "escalate":
            secret_name = user_manager.create_user(user_event)
            body = {"secret_name": secret_name}
        elif user_event.event_type == "deescalate":
            user_manager.delete_user(user_event)
            body = {}
        else:
            raise RuntimeError(f"Unsupported event type: {user_event.event_type}")
        result = {"body": body, "errors": []}
    except Exception as e:
        logger.error(e)
        result = {"body": {}, "errors": [str(e).rstrip()]}

    logger.debug("Result: %s", result)
    return result


def resolve_event(config: Config, event: dict) -> UserEvent:
    """
    Create a UserEvent data object with just the information we need from
    the incoming Sym payload.

    For more details on the event object format, refer to our reporting docs:
    https://docs.symops.com/docs/reporting
    """
    srn = event["run"]["srn"]
    run_id = SRN.parse(srn).identifier
    username = event["run"]["actors"]["request"]["username"]
    return UserEvent(
        db_user=format_db_user(username, run_id),
        event_type=event["event"]["type"],
        secret_name=f"/symops.com/{config.function_name}/{username}/{run_id}",
        target=event["fields"]["target"]["name"],
        username=username,
    )


def format_db_user(username: str, run_id: str) -> str:
    """
    Create a max 32 character database username based on the requesting username
    and a hash of the current run id
    """
    # Get a 24 character hash of the run id
    run_id_truncated = hashlib.shake_128(run_id.encode()).hexdigest(12)

    # Get the subject from the username if it is an email address
    subject = username.split("@")[0]
    # Remove non-word chars from the subject
    encoded_subject = re.sub(r"[\W]", "", subject)

    # Ensure resulting username is <= 32 chars
    return encoded_subject[0:12] + run_id_truncated


# Initialize stuff outside of the handler code so it can be reused across requests
try:
    config = get_config()
    conn = pymysql.connect(
        host=config.db_host,
        port=config.db_port,
        user=config.db_user,
        password=config.db_pass,
        connect_timeout=5,
    )
    user_manager = UserManager(config, conn)
except pymysql.MySQLError as e:
    print("ERROR: Unexpected error: Could not connect to DB")
    print(e)
    sys.exit()
except botocore.exceptions.ClientError as err:
    print("ERROR: Unexpected error: Could not connect initialize boto session")
    print(e)
    sys.exit()
