import os
from dataclasses import dataclass

import boto3


@dataclass
class Config:
    pg_host: str
    pg_port: int
    pg_user: str
    pg_pass: str


def get_config() -> Config:
    """
    Loads configuration from environment and SSM
    """
    return Config(
        pg_host=os.environ["PG_HOST"],
        pg_port=os.environ["PG_PORT"],
        pg_user=os.environ["PG_USER"],
        pg_pass=get_pg_password(),
    )


def get_pg_password() -> str:
    """
    Check if password is defined as an env var (for local testing)
    otherwise look up the value in Systems Manager Parameter Store.
    """
    if env_value := os.environ.get("PG_PASSWORD"):
        return env_value

    pg_password_key = os.environ.get("PG_PASSWORD_KEY", "/symops.com/PG_PASSWORD")

    ssm = boto3.client("ssm")
    result = ssm.get_parameter(Name=pg_password_key, WithDecryption=True)
    return result["Parameter"]["Value"]
