# Sym Implementation Examples

This repo provides full end to end examples for implementing various Sym Flows.

Full Sym docs can be found here:
- [Sym Docs](https://docs.symops.com/docs)
- [Sym SDK](https://sdk.docs.symops.com/)
- [Sym Terraform Provider](https://registry.terraform.io/providers/symopsio/sym/latest/docs)

## Content
Each folder in this repo represents a full end to end Sym Flow.

| Example                                                                       | Description                                                                        |
|-------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| [Approval-Only Flow](basic/approvals)                                         | A foundational Sym Flow for audited approvals                                      |
| [Aptible Access Strategy](basic/aptible_access_strategy)                      | A Sym Flow that escalates the requester to an Aptible role                         |
| [AWS IAM Group Escalation](basic/aws_iam_strategy)                            | A Sym Flow that escalates a user to an AWS IAM Group                               |
| [Invoke AWS Lambda from impl.py](basic/aws_lambda_sdk)                        | A Sym Flow that invokes an AWS Lambda from a hook in `impl.py`                     |
| [Custom Escalation with AWS Lambda](basic/aws_lambda_strategy)                | A Sym Flow that invokes an AWS Lambda for custom access management                 |
| [AWS IAM Identity Center (AWS SSO) Escalation](basic/aws_sso_strategy)        | A Sym Flow that assigns a user to an AWS Permission Set in a given AWS account     |
| [Datadog Log Destination](basic/datadog_log_destination)                      | A Sym Environment configured to send logs to Datadog via AWS Kinesis Firehose      |
| [GitHub Access Strategy](basic/github_access_strategy)                        | A Sym Flow that escalates the requester to a GitHub Repository                     |
| [GitHub Access Strategy with Dynamic Targets](basic/github_dynamic_targets)   | A GitHub Access Strategy that uses Dynamic Targets to populate the repository name |
| [Okta Group Escalation](basic/okta_access_strategy)                           | A Sym Flow that escalates the requester to an Okta Group                           |
| [Okta SDK Integration](basic/okta_sdk)                                        | Use the Okta SDK to create custom auth hooks and to get user profile data          |
| [Auto-approve PagerDuty On-call Engineer](basic/pagerduty_on_call)            | A Sym Flow that auto-approves requests if the requester is on-call in PagerDuty    |
| [AWS Kinesis Firehose to S3 Bucket Log Destination](basic/s3_log_destination) | A Sym Environment configured to send logs to an S3 bucket via AWS Kinesis Firehose |
| [Segment Log Destination](basic/segment_log_destination)                      | A Sym Environment configured to send logs to Segment                               |
| [Tailscale SSH Access](basic/tailscale_ssh_access)                            | A Sym Flow that escalates the requester to a Tailscale Group with SSH access       |

## Advanced
Advanced examples go beyond explaining the basics of Sym resources. Here you'll get deeper into setting up the target systems Sym is integrating with.

| Advanced Example                                                        | Description                                                                                                            |
|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [Approve a CircleCI Job from Sym](advanced/approve_circleci_job)        | A Sym Flow that is triggered from CircleCI by the Sym Orb and then resumes the paused CircleCI workflow after approval |
| [JIT access to multiple AWS Organizations](advanced/multi_tenant_sso_strategy) | Grant access to multiple tenant AWS Organizations from a centralized host AWS organization                      |
| [JIT access to SSH to EC2](advanced/aws_ec2_ssm)                        | A Sym Flow that grants SSH access to EC2 instances via AWS IAM Identity Center and AWS Session Manager                 |
| [Custom Integration](advanced/custom_integration)                       | A Sym Flow that uses a Custom Integration to wire in services that aren't directly supported by the SDK                |
| [Least Privilege S3 with K9 Security](advanced/k9_s3_target)            | Use a least-privilege bucket policy from K9 Security along with a Sym Flow to manage access to S3                      |
| [Multiple Environments](advanced/multiple_environments)                 | Use Sym Environments and Terraform modules to easily deploy a separate test Sym Flow                                   |
| [MySQL Temp User Strategy](advanced/mysql_temp_user_strategy)           | A Sym Flow that invokes an AWS Lambda to create temporary users to access to an AWS-hosted MySQL instance              |
| [Postgres Role Strategy](advanced/postgres_role_strategy)               | A Sym Flow that invokes an AWS Lambda to temporarily grant users additional roles in an AWS-hosted PostgreSQL instance |
| [Postgres Temp User Strategy](advanced/postgres_temp_user_strategy)     | A Sym Flow that invokes an AWS Lambda to create temporary users to access an AWS-hosted PostgreSQL instance            |
