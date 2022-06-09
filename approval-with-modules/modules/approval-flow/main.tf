resource "sym_flow" "this" {
  name  = "${var.environment_name}-approval"
  label = "Approval"

  template       = "sym:template:approval:1.0.0"
  implementation = "${path.module}/impl.py"
  environment_id = var.environment_id

  vars = var.flow_variables

  params = {
    # prompt_fields_json defines custom form fields for the Slack modal that
    # requesters fill out to make their requests.
    prompt_fields_json = jsonencode([
      {
        name     = "resource"
        label    = "What do you need access to?"
        type     = "string"
        required = true
      },
      {
        name     = "reason"
        label    = "Why do you need access?"
        type     = "string"
        required = true
      }
    ])
  }
}
