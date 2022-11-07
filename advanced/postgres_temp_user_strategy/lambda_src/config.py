import logging
import os
from dataclasses import dataclass
from pathlib import Path

import boto3
import botocore
from boto3.session import Session

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


@dataclass
class Config:
    boto_session: Session
    db_host: str
    db_name: int
    db_port: int
    db_user: str
    db_pass: str
    function_name: str
    targets: dict


def get_config() -> Config:
    """
    Loads configuration from environment and SSM
    """
    session = Session()
    return Config(
        db_host=os.environ["DB_HOST"],
        db_name=os.environ["DB_NAME"],
        db_port=int(os.environ["DB_PORT"]),
        db_user=os.environ["DB_USER"],
        db_pass=_get_db_password(session),
        function_name=os.environ["AWS_LAMBDA_FUNCTION_NAME"],
        boto_session=session,
        targets=_load_targets(),
    )


def _get_db_password(session: Session) -> str:
    """
    Check if password is defined as an env var (for local testing)
    otherwise look up the value in Systems Manager Parameter Store.
    """
    if env_value := os.environ.get("DB_PASSWORD"):
        return env_value

    db_password_key = os.environ.get("DB_PASSWORD_KEY", "/symops.com/DB_PASSWORD")

    # Use an aggressive timeout here so we get a helpful message during initialization
    # if the VPC cannot reach SSM. You can make this more lax if necessary.
    ssm = boto3.client(
        "ssm",
        config=botocore.config.Config(connect_timeout=5, retries={"max_attempts": 0}),
    )
    result = ssm.get_parameter(Name=db_password_key, WithDecryption=True)
    return result["Parameter"]["Value"]


def _load_targets() -> dict:
    """
    Read target sql files from the filesystem. The file that matches a requested
    target gets executed after a temp user is created for that target.
    """
    result = {}
    files = Path(os.environ["LAMBDA_TASK_ROOT"]).glob("targets/*.sql")
    for file in files:
        with file.open() as io:
            logger.debug("Loading target: %s", file.stem)
            result[file.stem] = io.read()
    return result
