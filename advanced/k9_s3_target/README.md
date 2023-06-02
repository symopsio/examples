# Least Privilege S3 Access with Sym and K9 Security

This example illustrates how to implement a Sym Flow that grants temporary access to an S3 Bucket that is managed with a [K9 Security](https://www.k9security.io/) least-privilege bucket policy.

**Update (June 1, 2023)**
In April 2023, AWS made security changes to S3. Please note that while the modules used in this example are now outdated and will not apply as-is, 
the concepts illustrated in this example are still valid, and may be used as a guideline for your own custom implementations.

## Blog

We discuss this example in more detail on our [blog](https://blog.symops.com/2022/11/10/stop-playing-whac-a-mole-start-using-least-privilege/).

For the basics on our AWS IAM Identity Center Strategy, check out a step-by-step tutorial [here](https://docs.symops.com/docs/aws-sso).

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
