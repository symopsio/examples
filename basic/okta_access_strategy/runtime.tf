# The runtime connector module creates both the AWS and Sym resources required to
module "runtime_connector" {
  source  = "symopsio/runtime-connector/aws"
  version = "~> 2.0"

  environment_name = local.environment_name
}
