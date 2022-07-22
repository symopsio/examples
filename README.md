# Sym Implementation Examples

This repo provides full end to end examples for implementing various Sym Flows.

Full Sym docs can be found here:
- [Sym Docs](https://docs.symops.com/docs)
- [Sym SDK](https://sdk.docs.symops.com/)
- Sym Terraform Provider (Coming Soon!)

## Content
Each folder in this repo represents a full end to end Sym Flow.

| Example                                                                 | Description                                                                                                            |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| [Approval-Only Flow](approvals)                                         | A foundational Sym Flow for audited approvals                                                                          |
| [Aptible Access Strategy](aptible_access_strategy)                      | A Sym Flow that escalates the requester to an Aptible role                                                             |
| [AWS IAM Group Escalation](aws_iam_strategy)                            | A Sym Flow that escalates a user to an AWS IAM Group                                                                   |
| [Invoke AWS Lambda from impl.py](aws_lambda_sdk)                        | A Sym Flow that invokes an AWS Lambda from a hook in `impl.py`                                                         |
| [Custom Escalation with AWS Lambda](aws_lambda_strategy)                | A Sym Flow that invokes an AWS Lambda for custom access management                                                     |
| [Datadog Log Destination](datadog_log_destination)                      | A Sym Environment configured to send logs to Datadog via AWS Kinesis Firehose                                          |
| [GitHub Access Strategy](github_access_strategy)                        | A Sym Flow that escalates the requester to a GitHub Repository                                                         |
| [GitHub Access Strategy with Dynamic Targets](github_dynamic_targets)   | A GitHub Access Strategy that uses Dynamic Targets to populate the repository name                                     |
| [Okta Group Escalation](okta_access_strategy)                           | A Sym Flow that escalates the requester to an Okta Group                                                               |
| [Auto-approve PagerDuty On-call Engineer](pagerduty_on_call)            | A Sym Flow that auto-approves requests if the requester is on-call in PagerDuty                                        |
| [AWS Kinesis Firehose to S3 Bucket Log Destination](s3_log_destination) | A Sym Environment configured to send logs to an S3 bucket via AWS Kinesis Firehose                                     |
| [Segment Log Destination](segment_log_destination)                      | A Sym Environment configured to send logs to Segment                                                                   |
| [Tailscale SSH Access](tailscale_ssh_access)                            | A Sym Flow that escalates the requester to a Tailscale Group with SSH access                                           |

## Advanced
Advanced examples go beyond explaining the basics of Sym resources. Here you'll get deeper into setting up the target systems Sym is integrating with.

| Advanced Example                                                        | Description                                                                                                            |
|-------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [Approve a CircleCI Job from Sym](advanced/approve_circleci_job)        | A Sym Flow that is triggered from CircleCI by the Sym Orb and then resumes the paused CircleCI workflow after approval |
| [Custom Integration](advanced/custom_integration)                       | A Sym Flow that uses a Custom Integration to wire in services that aren't directly supported by the SDK                |
| [Postgres Access Strategy](advanced/postgres_lambda_strategy)           | A Sym Flow that invokes an AWS Lambda to manage access  to an AWS-hosted Postgres instance                             |
