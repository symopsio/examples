# Postgres Lambda Strategy

A starter template that implements a Postgres Sym Flow using an AWS Lambda to manage database user permissions.

## Tutorial

Our step-by-step [PostgreSQL on AWS tutorial](https://docs.symops.com/docs/postgres-on-aws) walks you through setup for this example.

## Setting up an example database

Enable the [`postgres_db`](postgres_db) module to provision an RDS Postgres database in a VPC that you can use to test the integration.

You can enable the module by setting the `db_enabled` variable to true.

Refer to the [`README`](postgres_db/README.md) for instructions on tunneling to the example database.

## Local testing

You can iterate on your handler function locally by setting up a docker compose based Postgres database and then invoking your handler function directly.

1. Start the local database with [`docker compose up`](lambda_src/test/docker-compose.yaml).
2. Copy [`env.example`](lambda_src/test/env.example) to `.env` and then `source` it into your shell
3. Create a test user, database and role with [`init-users.sh`](lambda_src/test/init-users.sh).
4. Run `pip install -r requirements.txt`
5. Run `cat test/escalate.json | python handler.py` to grant a user access to the readonly role.
6. Verify the user grants by running `\du` from the `psql` console.

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
