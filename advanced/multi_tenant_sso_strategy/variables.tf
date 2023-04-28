variable "customer_tenants" {
  type = map(object({
    sso_connector_settings = object({
      cloud        = string,
      instance_arn = string,
      region       = string,
      role_arn     = string
    })
    permission_set_arn = string
    account_id         = string
  }))
}
