# aws secretsmanager put-secret-value --secret-id "main/segment-write-key" --secret-string "YOUR-SEGMENT-WRITE-KEY"
resource "aws_secretsmanager_secret" "segment_write_key" {
  name        = "main/segment-write-key"
  description = "Segment Write Key for Sym Audit Logs"

  tags = {
    # This SymEnv tag is required and MUST match the `environment` in your `runtime_connector` module
    # because the aws/secretsmgr only grants access to secrets tagged with a matching SymEnv value
    SymEnv = "main"
  }
}

resource "sym_secret" "segment_write_key" {
  # `sym_secrets` is defined in "Manage Secrets with AWS Secrets Manager"
  source_id = sym_secrets.this.id
  path      = aws_secretsmanager_secret.segment_write_key.name
}

resource "sym_integration" "segment" {
  type = "segment"
  name = "main-segment-integration"

  # Your Segment Workspace name
  external_id = "sym-test"

  settings = {
    # This secret was defined in the previous step
    write_key_secret = sym_secret.segment_write_key.id
  }
}

############ Log Destination Setup ##############

resource "sym_log_destination" "segment" {
  type           = "segment"
  integration_id = sym_integration.segment.id

  settings = {
    # A unique name for this log destination
    stream_name = "segment-main"
  }
}

resource "sym_flow" "this" {
  name  = "approval"
  label = "Approval"

  implementation = "${path.module}/impl.py"
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