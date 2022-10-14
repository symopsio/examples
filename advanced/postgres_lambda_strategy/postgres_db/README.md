# postgres-db

This is a helper module that will set up a VPC and RDS instance that you can use for testing out the Sym Postgres integration.

## Reading the Database Configuration

To get the connection info for the example db, use the `terraform output` command. Note that in a production setting you should not store the database password in Terraform state.

```bash
$ terraform output db_config
tomap({
  "host" = "symdb.bcdefg12345.us-east-1.rds.amazonaws.com"
  "pass" = "mydbpassword"
  "port" = "5432"
  "user" = "symdb"
})
```

## SSH Tunneling

We've included a bastion EC2 instance that you can use to connect to the database over an SSH tunnel using [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). Here's an example that forwards database traffic to local port 5433, using the outputs from `terraform output dbconfig`:

```bash
$ ./tunnel.sh --endpoint symdb.abcdefg12345.us-east-1.rds.amazonaws.com \
  --remort-port 5432 \
  --local-port 5433 \
  --namespace = sym
```

Once you have the tunnel open, you can connect to the database on `localhost`, using using the username and password from `terraform output dbconfig`.
