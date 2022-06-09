provider "sym" {
  org = var.sym_org_slug
}


module "sym_shared" {
  source = "../modules/sym-shared"

  environment_name   = var.environment_name
  error_channel_name = var.error_channel_name
  slack_workspace_id = var.slack_workspace_id
}

module "approval_flow" {
  source = "../modules/approval-flow"

  environment_name = var.environment_name
  environment_id   = module.sym_shared.environment_id
  flow_variables   = var.flow_variables
}
