provider "sym" {
  org = "sym-example"
}

# Create all the necessary resources for an approval flow using a resuable module.
# This one will be our stable environment for daily use.
module "main_approval_flow" {
    source = "../../modules/sym"

    # Resources will contain "main" in their name to differentiate environments.
    environment_name = "main"
    error_channel_name = "#sym-errors"
    slack_workspace_id = "T123ABC"

    flow_variables = {
      request_channel = "#sym-requests"      # Slack Channel where requests should go
      approvers       = "foo@symops.io,bar@myco.com" # Optional safelist of users that can approve requests
    }
}
