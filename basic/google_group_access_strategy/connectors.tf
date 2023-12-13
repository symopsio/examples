provider "google" {}

# The gcp_connector module creates the resources necessary for the Sym Runtime to access Google Cloud Resources
# via Workload Identity Federation. For more information, see: https://cloud.google.com/iam/docs/workload-identity-federation
module "gcp_connector" {
  source  = "symopsio/gcp-connector/google"
  version = "~> 1.0"

  environment = local.environment_name

  # Google recommends using a dedicated project for your Workload Identity Pools. Specify that project's ID here.
  # https://cloud.google.com/iam/docs/best-practices-for-using-workload-identity-federation#dedicated-project
  identity_pool_project_id = "my-identity-pools"
  gcp_org_id               = "123456789"

  # For the Sym Integration to manage Google Groups, the Admin SDK API must be enabled.
  # Note: This only enables the API, and there are still manual steps required to assign the
  # generated service account a custom Admin Role in the Google Workspace Admin Console!
  # See; https://docs.symops.com/docs/google
  enable_google_group_management = true
}

# Print the email of the created service account to the console when this configuration is applied.
output "sym_service_account" {
  value = module.gcp_connector.service_account.email
}
