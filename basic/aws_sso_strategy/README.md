# AWS IAM Identity Center (AWS SSO) Access Strategy

This example illustrates how to implement a Sym Flow that uses an AWS IAM Identity Center (AWS SSO) Strategy to grant users temporary access to an AWS Permission Set or an AWS SSO Group.

## Tutorial

Check out a step-by-step tutorial [here](https://docs.symops.com/docs/aws-sso).

### A Note on AWS Profiles

This example assumes you will configure the Sym Runtime into one AWS account, and the SSO connector IAM role into the account where your AWS SSO instance is provisioned.

You should update the provider configurations for each as necessary:

```hcl
# Set up this AWS provider for the AWS account where the Sym Runtime and any other
# supporting resources for Sym can go, like reporting streams with AWS Kinesis.
provider "aws" {
  region = "us-east-1"
}

# Set up a different provider for the SSO connector.
# This is because you typically will put your Sym resources in a different
# AWS account from your AWS SSO instance.
provider "aws" {
  alias  = "sso"
  region = "us-east-1"

  # Change this profile name to a valid AWS profile for the AWS account where
  # your AWS SSO instance lives.
  profile = "sso"
}
```

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
