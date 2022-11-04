#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -u

#######################################
# Ensure that a command exists
# Arguments:
#   The command to check
#######################################
require() {
  command -v "$1" > /dev/null 2>&1 || {
    echo "Some of the required software is not installed:"
    echo "    please install $1" >&2
    exit 1
  }
}

HOST=localhost
DATABASE=postgres
PORT=5433
USER=postgres
PASSWORD=postgres
DB_NAME=app

require psql

# https://aws.amazon.com/blogs/database/managing-postgresql-users-and-roles/
# \du to check

PGPASSWORD="${PASSWORD}" \
  psql -v ON_ERROR_STOP=1 \
  --host="${HOST}" \
  --port="${PORT}" \
  --dbname="${DATABASE}" \
  --username "${USER}" <<-EOSQL
  CREATE DATABASE $DB_NAME;
  REVOKE ALL ON DATABASE $DB_NAME FROM PUBLIC;
  CREATE ROLE readonly;
  GRANT CONNECT ON DATABASE $DB_NAME TO readonly;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
  CREATE USER sym_user WITH PASSWORD 'sym_user';
EOSQL
