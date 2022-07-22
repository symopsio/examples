# Postgres Lambda Strategy

A starter template that implements a Postgres Sym Flow using an AWS Lambda to manage database user permissions.

## Tutorial

Our step-by-step Lambda [tutorial](https://docs.symops.com/docs/aws-lambda) will get you most of the way through the setup for Postgres.

### Setting up Postgres roles and users

You need to configure Postgres roles that Sym can grant and revoke access to. Each role should correspond to a `sym_target` in [`main.tf`](main.tf).

You'll also need to ensure you can map users from Sym into your database. There is a placeholder implementation of this in the [`resolve_user`](lambda_src/handler/handler.py) method in `handler.py`.

An example script to set up roles and users is in our test [`init-users.sh`](lambda_src/test/init-users.sh) script.

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
