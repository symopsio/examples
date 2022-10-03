# Temporary EC2 SSH Access with AWS Systems Manager Session Manager

This example illustrates how to implement a Sym Flow that uses an AWS IAM Identity Center (AWS SSO) Strategy to grant users temporary SSH access to an EC2 Instance.

The example relies on [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) (Session Manager).

A diff between this example and the basic [Approval](../approvals) example: [Diff](https://github.com/symopsio/examples/compare/1e4b8b03e089b8b55cfd81b8e580637fdc502e79...7b0f47fda4d044d5ef5471ce651dfc60567708a8)

## Test Bastion Instances

You can provision test bastion instances to validate the SSH setup by setting `bastions_enabled` to `true`.

Note that if you enable test instances, you also need to configure the `private_subnet_id` variable.

## Blog

We discuss this example in more detail on our [blog]().

For the basics on our AWS IAM Identity Center Strategy, check out a step-by-step tutorial [here](https://docs.symops.com/docs/aws-sso).

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
