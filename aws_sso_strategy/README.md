# AWS SSO Access Strategy

This example illustrates how to implement a Sym Flow that uses an AWS SSO Strategy to grant users temporary access to an AWS SSO Permission Set.

A diff between this example and the basic [Approval](../approvals) example: [Diff](https://github.com/symopsio/examples/compare/5b76c7ec7f23014b8aeb8e09c94165848d90780c...7b0f47fda4d044d5ef5471ce651dfc60567708a8)

## Tutorial

Check out a step-by-step tutorial [here](https://docs.symops.com/docs/aws-sso).

### A note on AWS Profiles

This example assumes you will configure Sym's runtime into one AWS account, and the SSO connector IAM role into the account where your AWS SSO instance is provisioned.

You should update the provider configurations for each as necessary:

```hcl
# Set up this AWS provider for the AWS account where Sym's runtime and any other
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
