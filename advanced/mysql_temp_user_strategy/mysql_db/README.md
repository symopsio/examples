# mysql-db

This is a helper module that will set up a VPC and RDS instance that you can use for testing out the Sym MySQL integration.

## Reading the Database Configuration

To get the connection info for the example db, use the `terraform output` command. Note that in a production setting you should not store the database password in Terraform state.

```bash
$ terraform output db_config
tomap({
  "host" = "symdb.abcdefg12345.us-east-1.rds.amazonaws.com"
  "pass" = "mydbpassword"
  "port" = "3306"
  "user" = "symdb"
})
```

## SSH Tunneling

We've included a bastion EC2 instance that you can use to connect to the database over an SSH tunnel using [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). Here's an example that forwards database traffic to local port 3308, using the outputs from `terraform output db_config`:

```bash
$ ./tunnel.sh --endpoint symdb.abcdefg12345.us-east-1.rds.amazonaws.com \
  --remort-port 3306 \
  --local-port 3308
```

Once you have the tunnel open, you can connect to the database on `localhost`, using using the username and password from `terraform output db_config`.
