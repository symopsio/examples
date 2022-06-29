# Sym Implementation Examples

This repo provides full end to end examples for implementing various Sym Flows.

Full Sym docs can be found here:
- [Sym Docs](https://docs.symops.com/docs)
- [Sym SDK](https://sdk.docs.symops.com/)
- Sym Terraform Provider (Coming Soon!)

## Content
Each folder in this repo represents a full end to end Sym Flow.

| Example                                                      | Description                                                                                                            |
|--------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [Approval-Only Flow](approvals)                              | A foundational Sym Flow for audited approvals                                                                          |
| [Approve a CircleCI Job from Sym](approve_circleci_job)      | A Sym Flow that is triggered from CircleCI by the Sym Orb and then resumes the paused CircleCI workflow after approval |
| [AWS IAM Group Escalation](aws_iam_strategy)                 | A Sym Flow that escalates a user to an AWS IAM Group                                                                   |
| [Invoke AWS Lambda from impl.py](aws_lambda_sdk)             | A Sym Flow that invokes an AWS Lambda from a hook in `impl.py`                                                         |
| [Okta Group Escalation](okta_access_strategy)                | A Sym Flow that escalates the requester to an Okta Group                                                               |
| [Auto-approve PagerDuty On-call Engineer](pagerduty_on_call) | A Sym Flow that auto-approves requests if the requester is on-call in PagerDuty                                        |
