# Approving a CircleCI Job with Sym
This section illustrates how to use the [Sym Orb](https://circleci.com/developer/orbs/orb/sym/sym) in your CircleCI pipeline and how to approve a CircleCI job with hooks

A diff between this example and the basic [Approval](../approvals) example: [Diff](https://github.com/symopsio/examples/compare/c6453075e3a1d10a7a80b9ec55f0dc5a516044e4...1d9fcbf54d579331a54b8ad0ac9dc5548a30fda7)

## Tutorial

Check out a step-by-step tutorial [here](https://docs.symops.com/docs/circleci-and-sym).

# Sequence diagram of the approval process

![](img/deploy_sequence.jpg)

## Gating a CircleCI job with a Sym Approval

This approval flow will be triggered by the `sym/request` job in your CircleCI workflow.
Once approved, Sym will automatically resume the workflow after the `wait_for_sym_approval` job.

```yaml
# Add the Sym orb to your config.yml
orbs:
  sym: sym/sym@1.0.0

workflows:
  main:
    jobs:
      # This will start the Sym flow
      - sym/request:
          flow_srn: sym:flow:ci-approval-prod:latest
          flow_inputs: '{
                      "workflow_url": "${CIRCLE_BUILD_URL}",
                      "merging_user": "${CIRCLE_USERNAME}",
                      "workflow_id": "${CIRCLE_WORKFLOW_ID}"
                  }'
          requires:
            - terraform_acceptance_test
          context: sym-bot-token

      # The workflow will pause here and wait for approval.
      # Once approved, Sym will approve this job to continue the workflow
      - wait_for_sym_approval:
          type: approval
          requires:
            - sym/request

      # After approving the Sym request in Slack, CircleCI will continue to this job
      - deploy_prod:
          requires:
            - wait_for_sym_approval
          ...
```

For more information of the Sym CircleCI orb, please check out [our docs](https://circleci.com/developer/orbs/orb/sym/sym).

## About Sym

This workflow is just one example of how [Sym Implementers](https://docs.symops.com/docs/sym-for-implementers) use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/flows).
