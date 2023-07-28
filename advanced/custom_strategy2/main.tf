locals {
  custom_flow_name = "custom-flow"
}

resource "sym_flow" "custom" {
  name  = local.custom_flow_name
  label = "Custom Access"

  implementation = file("${path.module}/flow_impl.py")
  environment_id = sym_environment.staging.id
  vars           = var.flow_vars

  params {
    strategy_id           = sym_strategy.custom.id
    schedule_deescalation = false
    prompt_field {
      name     = "identifier"
      label    = "What animal?"
      type     = "string"
      required = true
    }
  }
}

resource "sym_strategy" "custom" {
  type = "custom"

  name           = local.custom_flow_name
  integration_id = sym_integration.custom.id
  targets        = [sym_target.custom.id]
  implementation = file("${path.module}/impls/strategy/animals.py")
}

resource "sym_target" "custom" {
  type  = "custom"
  name  = "${local.custom_flow_name}-target"
  label = "Custom Test Target"

  field_bindings = ["identifier"]
}

resource "sym_integration" "custom" {
  type = "custom"
  name = "${local.custom_flow_name}-integration"

  external_id = "idontmattereither"

  settings = {
    secret_ids_json = jsonencode([sym_secret.coda_api_key.id])
  }
}

resource "aws_secretsmanager_secret" "coda_api_key" {
  name                    = "sym-staging/custom-strategy/coda-api-key"
  recovery_window_in_days = 0
  description             = "Coda API key for the Coda doc access custom Strategy"
  tags                    = var.tags
}

resource "sym_secret" "coda_api_key" {
  path      = aws_secretsmanager_secret.coda_api_key.name
  source_id = sym_secrets.this.id
}
