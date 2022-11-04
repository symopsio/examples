# MySQL Temp User Strategy

Manage access to an RDS MySQL instance by creating temporary database users that are stored in AWS Secrets Manager.

## Tutorial

Our step-by-step [MySQL on AWS tutorial](https://docs.symops.com/docs/mysql-on-aws) walks you through setup for this example.

## Setting up an example database

Enable the [`mysql_db`](mysql_db) module to provision an RDS MySQL database in a VPC that you can use to test the integration.

You can enable the module by setting the `db_enabled` variable to true.

Refer to the [`README`](mysql_db/README.md) for instructions on tunneling to the example database.

## Testing

You can use the provided [test events](lambda_src/test) to [test your function](https://docs.aws.amazon.com/lambda/latest/dg/testing-functions.html) in the Lambda console.

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
