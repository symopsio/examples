# Overview
Welcome to Sym!

Sym helps you code your way out of messy access management problems with approval workflows built in
Python and Terraform. Run these Sym Flows in Slack for seamless access management across all of your teams.

In this directory, you will find a set of files that represent the common Terraform configuration required to start building any Sym Flow.

- `environment.tf`: A file declaring general configuration about the environment you will deploy Sym Flows to (e.g. prod, sandbox). Things like what Slack workspace you'll be using and where errors will go live here.
- `versions.tf`: A file declaring the Sym Terraform provider version.

When you're ready to configure your first Sym Flow, run `symflow generate` in this directory!

If you have any questions or feedback, please reach out to us at support@symops.com.

# Helpful Links
- [Sym Docs](https://docs.symops.com/)
- [Sym Terraform Provider Docs](https://registry.terraform.io/providers/symopsio/sym/latest/docs)
- [Sym Implementation Examples](https://github.com/symopsio/examples)

# Configuration Details
## environment.tf
### [sym_environment](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/environment)
The `sym_environment` resource is a collection of shared configuration for your Flows.
For example, it will tell your Flow where to send errors and which Integrations to use.

`symflow init` will create an Error Logger to capture any errors that occur when running Flows in this Environment. There is also a single Integration with Slack that tells Sym which Slack workspace to send requests to.

### [sym_integration](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/integration)
`sym_integration` resources allow you to provide Sym with the credentials and context to connect to an external service.
In this case, the Slack Integration only needs your Workspace ID.

### [sym_error_logger](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/error_logger)
The `sym_error_logger` resource configures a channel in Slack as the destination for any warnings and errors that occur during
the execution of a Flow. By default, it is configured to send messages to the `#sym-errors` channel. **Make sure
that you create this channel in your workspace! Otherwise, the messages will not be delivered.**

## After Running `symflow generate`
When you're ready to set up your first Flow, run `symflow generate` in this directory. That will create a set of new Terraform resources for the type of Flow you choose. Most resources will differ based on the chosen type of Flow, but you'll always have the following:

### [sym_flow](https://registry.terraform.io/providers/symopsio/sym/latest/docs/resources/flow)
The `sym_flow` resource defines the Flow that a user will run in Slack. By default, the generated `sym_flow` resource will almost always have the following attributes:
- `name`: A unique, human-readable identifier for the Flow.
- `label`: The display name for the Flow. This is what you'll see in Slack.
- `implementation`: The path to a file where the Sym Python SDK will be used to customize the workflow. In this case, `<YOUR_FLOW>_impl.py`
- `environment_id`: The Environment this Flow belongs to (e.g. `prod`, `staging`, `sandbox`). See `sym_environment` above.
- `params`: A Terraform block containing parameters to customize this Flow's behavior.
  - `prompt_field`: Terraform blocks describing what inputs to show users when this Flow is run.

### impl.py
The `impl.py` file is a Python file that allows you to customize your Flow's logic in Python. You should have a new directory, `impls`, containing an `impl.py` specific to your Flow (e.g. `my_okta_impl.py` if you generated an Okta Flow). This is where you may
implement any number of [Hooks and Reducers](https://docs.symops.com/docs/workflow-handlers).
- Reducers are prefixed with `get_`, and return a single value.
- Hooks are prefixed with `on_` or `after_`, and allow you to alter control flow by inserting custom logic before or after an Event is processed.

In this example, the `impl.py` file implements a single Reducer `get_approvers`, which tells Sym where to send
requests in Slack. This example returns the channel `#sym-requests`, and allows requesters
to approve their own requests (`allow_self=True`).

While the `get_approvers` Reducer is the only required part of an `impl.py`, there are many [Hooks](https://docs.symops.com/docs/hooks)
that you may implement to customize your Flow's logic. For example, you might want to implement an
[`on_request` Hook](https://docs.symops.com/docs/hooks#on_request) that auto-approves users that are on-call on PagerDuty.
