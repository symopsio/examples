############ Creating a Kinesis Firehose Delivery Stream to Datadog ##############

# This module creates a AWS Kinesis Firehose Delivery Stream that pipes logs to Datadog
module "datadog_connector" {
  source  = "symopsio/datadog-connector/aws"
  version = ">= 2.0.0"

  environment = "main"

  # This variable should NOT be checked into version control!
  # Set it in an untracked tfvars file (e.g. `secrets.tfvars`)
  # or as an environment variable: `export TF_VAR_datadog_access_key="my-access-key"`
  datadog_access_key = var.datadog_access_key
}

resource "sym_log_destination" "datadog" {
  type = "kinesis_firehose"

  # The Runtime Permission Context has Kinesis Firehose permissions
  integration_id = sym_integration.runtime_context.id

  settings = {
    # The firehose stream name is outputted by the datadog_connector module
    stream_name = module.datadog_connector.firehose_name
  }
}


resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = "${path.module}/impl.py"

  # The sym_environment resource is defined in `environment.tf`
  environment_id = sym_environment.this.id

  params {
    # Each prompt_field defines a custom form field for the Slack modal that
    # requesters fill out to make their requests.
    prompt_field {
      name     = "resource"
      label    = "What do you need access to?"
      type     = "string"
      required = true
    }

    prompt_field {
      name     = "reason"
      label    = "Why do you need access?"
      type     = "string"
      required = true
    }
  }
}
