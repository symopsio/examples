import os
from dataclasses import dataclass

from boto3.session import Session


@dataclass
class Config:
    boto_session: Session
    db_host: str
    db_port: int
    db_user: str
    db_pass: str
    function_name: str


def get_config() -> Config:
    """
    Loads configuration from environment and SSM
    """
    session = Session()
    return Config(
        db_host=os.environ["DB_HOST"],
        db_port=int(os.environ["DB_PORT"]),
        db_user=os.environ["DB_USER"],
        db_pass=_get_db_password(session),
        function_name=os.environ["AWS_LAMBDA_FUNCTION_NAME"],
        boto_session=session,
    )


def _get_db_password(session: Session) -> str:
    """
    Check if password is defined as an env var (for local testing)
    otherwise look up the value in Systems Manager Parameter Store.
    """
    if env_value := os.environ.get("DB_PASSWORD"):
        return env_value

    db_password_key = os.environ.get("DB_PASSWORD_KEY", "/symops.com/DB_PASSWORD")

    ssm = session.client("ssm")
    result = ssm.get_parameter(Name=db_password_key, WithDecryption=True)
    return result["Parameter"]["Value"]
