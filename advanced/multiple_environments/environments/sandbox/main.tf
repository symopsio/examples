provider "sym" {
  org = "sym-example"
}

# Create all the necessary resources for an approval flow using a resuable module.
# This one will be a sandbox environment for testing new ideas.
module "sandbox_approval_flow" {
    source = "../../modules/sym"

    # Resources will contain "sandbox" in their name to differentiate environments.
    environment_name = "sandbox"
    error_channel_name = "#sym-sandbox-errors"
    slack_workspace_id = "T123ABC"

    # Configure the sym_flow to send sandbox requests to their own Slack channel.
    flow_variables = {
      request_channel = "#sym-sandbox-requests"      # Slack Channel where requests should go
      approvers       = "foo@symops.io,bar@myco.com" # Optional safelist of users that can approve requests
    }
}
