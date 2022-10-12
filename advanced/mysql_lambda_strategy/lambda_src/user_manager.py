import json
import logging
import os
import secrets
import string
from dataclasses import dataclass
from typing import Optional

from boto3.session import Session
from pymysql.connections import Connection

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


@dataclass
class UserEvent:
    """The properties that a UserManager needs to create/delete users"""

    db_user: str
    event_type: str
    secret_name: str
    target: str
    username: str


class UserManager:
    """Creates or deletes users given a UserEvent"""

    def __init__(self, session: Session, conn: Connection):
        self._secretsmgr = session.client(service_name="secretsmanager")
        self._conn = conn

    def create_user(self, event: UserEvent) -> str:
        """Creates a secrets manager secret and a database user for the given event"""
        password = self._generate_password()
        secret_name = self._create_secret(event, password)
        self._create_db_user(event, password)
        return secret_name

    def delete_user(self, event: UserEvent) -> None:
        """Deletes a secrets manager secret and a database user for the given event"""
        self._drop_db_user(event)
        self._delete_secret(event)

    def _generate_password(self) -> str:
        """Generate a cryptographically secure password using the secrets module"""
        alphabet = string.ascii_letters + string.digits
        return "".join(secrets.choice(alphabet) for i in range(16))

    def _create_secret(self, event: UserEvent, password: str) -> str:
        """
        Create a secrets manager secret and tag it with sym.user, so that we can
        create an IAM policy that allows users to access their own secrets by tag.
        """
        logger.debug("Creating secret: %s", event.secret_name)
        response = self._secretsmgr.create_secret(
            Name=event.secret_name,
            Description=f"Sym-generated temporary password for user: {event.username}",
            SecretString=json.dumps({"username": event.db_user, "password": password}),
            Tags=[
                {"Key": "sym.user", "Value": event.username},
            ],
        )
        return response["Name"]

    def _delete_secret(self, event: UserEvent) -> None:
        """
        Delete the secrets manager secret without a recovery window, since this is for a
        temporary user that has already been deleted.
        """
        logger.debug("Deleting secret: %s", event.secret_name)
        self._secretsmgr.delete_secret(
            SecretId=event.secret_name,
            ForceDeleteWithoutRecovery=True,
        )

    def _create_db_user(self, event: UserEvent, password: str) -> None:
        """
        Create a database user and execute any additional statements
        that were configured for the specific target the user requested
        access to
        """
        stmt = "CREATE USER %s IDENTIFIED BY %s"
        logger.debug(stmt, event.db_user, "<redacted>")
        with self._conn.cursor() as cur:
            cur.execute(stmt, [event.db_user, password])
            target_stmt = self._load_target_stmt(event)
            if target_stmt:
                target_args = {"username": event.db_user}
                logger.debug(target_stmt, target_args)
                cur.execute(target_stmt, target_args)

    def _load_target_stmt(self, event: UserEvent) -> Optional[str]:
        """Load sql that corresponds to the target the user requested"""
        sql_path = os.environ["LAMBDA_TASK_ROOT"] + f"/targets/{event.target}.sql"
        if not os.path.exists(sql_path):
            logger.debug("No target sql found for target: %s", event.target)
            return None

        with open(sql_path) as f:
            result = f.read()
        return result

    def _drop_db_user(self, event: UserEvent) -> None:
        stmt = "DROP USER IF EXISTS %s"
        logger.debug(stmt, event.db_user)
        with self._conn.cursor() as cur:
            cur.execute(stmt, [event.db_user])
