
############ Google Group Strategy Setup ##############

# A target Google Group that your Sym Strategy can manage access to
resource "sym_target" "super_user_google_group" {
  type  = "google_group"
  name  = "${local.environment_name}-super-users"
  label = "Super Users"

  settings = {
    # `type=google_group` sym_targets have the required settings `group_email` and `role`,
    # where `group_email` is the email of the Google Group the requester will be escalated to,
    # and `role` is the Google Group Role the requester will be assigned.
    group_email = "super-users@compliance.dev"
    role        = "MEMBER"
  }
}

resource "sym_target" "read_only_google_group" {
  type  = "google_group"
  name  = "${local.environment_name}-read-only"
  label = "Read Only"

  settings = {
    # `type=google_group` sym_targets have the required settings `group_email` and `role`,
    # where `group_email` is the email of the Google Group the requester will be escalated to,
    # and `role` is the Google Group Role the requester will be assigned.
    group_email = "read-only@compliance.dev"
    role        = "MEMBER"
  }
}


# The Strategy your Flow uses to escalate to Google Groups
resource "sym_strategy" "google_group" {
  type           = "google_group"
  name           = "${local.environment_name}-google-group"
  integration_id = module.gcp_connector.sym_integration.id

  # This must be a list of `google_group` sym_targets that users can request to be escalated to
  targets = [sym_target.super_user_google_group.id, sym_target.read_only_google_group.id]
}

resource "sym_flow" "this" {
  name  = "google"
  label = "Google Group Access"

  implementation = file("${path.module}/impl.py")

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # By specifying a strategy, this Flow will now be able to manage access (escalate/de-escalate)
    # to the targets specified in the `sym_strategy` resource.
    strategy_id = sym_strategy.google_group.id

    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }

    prompt_field {
      name           = "duration"
      type           = "duration"
      allowed_values = ["1h", "1d", "10d"]
      required       = true
    }
  }
}
