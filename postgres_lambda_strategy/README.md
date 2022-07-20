# Postgres Lambda Strategy

A starter example that implements a Postgres Sym Flow using an AWS Lambda to manage database user permissions.

## Tutorial

Our step-by-step Lambda [tutorial](https://docs.symops.com/docs/aws-lambda) will get you most of the way through the setup for Postgres.

### Set up Postgres Roles and Users

You need to configure Postgres roles that Sym can grant and revoke access to. Each role should correspond to a `sym_target` in [`main.tf`](main.tf).

You'll also need to ensure you can map users from Sym into your database. There is a placeholder implementation of this in the [`resolve_user`](src/handler/handler.py) method in `handler.py`.

An example script to set up roles and users is in our test [`init-users.sh`](src/test/init-users.sh) script.

## Example database setup

We've included a [helper module](helper) that you can use to provision a VPC and an RDS Postgres database suitable for testing the integration.

Use the outputs of the helper module as input variables to finish setting up an end to end example.

## Local testing

You can iterate on your handler function locally by setting up a docker compose based Postgres database and then invoking your handler function directly.

1. Start the local database with [`docker compose`](src/test/docker-compose.yaml).
2. Create a test user, database and role with [`init-users.sh`](src/test/init-users.sh).
3. Copy [`env.example`](src/test/env.example) to `.env` and then `source` it into your shell
4. Run `pip install -r requirements.txt`
5. Run `cat ../test/escalate.json | python handler.py` to grant a user access to the readonly role.
6. Verify the user grants by running `\du` from the `psql` console.

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
