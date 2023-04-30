# JIT access to multiple AWS Organizations

This example shows how to implement Sym flows that grant users access to multiple AWS Organizations from a centralized host AWS Organization. This setup is useful for a service provider that needs to work in the AWS account structure of many customer organizations.

## Terminology

* Host AWS Organization: This is the organization that is setting up Sym, and has users that need access to other AWS Organizations.
* Tenant AWS Organization: This is one of the many AWS Organizations that users from the host organization need access to.

## Approach

We will define centralized resources for Sym in the host AWS Organization, and then define a Sym flow that manages JIT access for each tenant AWS Organization.

Sym needs an [SSO Connector](https://registry.terraform.io/modules/symopsio/sso-connector/aws/latest) defined for each SSO instance that it will manage. We assume that the SSO Connector roles get created through separate processes, depending on the rules and configurations for each AWS Organization.

Even though the SSO Connectors are different, in many cases the flow configurations for each tenant organization will be the same.  We create an [`sso_flow`](sso_flow) module that encapsulates the common configurations for each flow.

## Adding new tenants

Add a configuration object to `customer_tenants` in [`terraform.tfvars`](terraform.tfvars) and then this example will add a new SSO flow for that tenant. Each configuration object takes the minimum required configurations to set up an SSO flow:

1. `sso_account_id`: The tenant AWS Accuont ID where the SSO Connector Role is defined
2. `sso_connector_settings`: The settings created by Sym's SSO Connector module for this tenant
3. `permission_set_arn`: The Permission Set that users can request access to in the tenant organization
4. `target_account_id`: The Account ID that users can request access to in the tenant organization

Note that you can also update the `sso_flow` module to provide a list of Permission Set/Account ID pairs if that matches your use case.

```
customer_tenants = {
  tenant_foo = {
    sso_account_id = "1234567890"
    sso_connector_settings = {
      "cloud"        = "aws"
      "instance_arn" = "arn:aws:sso:::instance/ssoins-000000"
      "region"       = "us-east-1"
      "role_arn"     = "arn:aws:iam::1234567890:role/sym/SymSSOTenant-Foo"
    }
    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-000000/ps-000000"
    target_account_id  = "333333333"
  },
  tenant_bar = {
    sso_account_id = "555555555"
    sso_connector_settings = {
      "cloud"        = "aws"
      "instance_arn" = "arn:aws:sso:::instance/ssoins-1111111"
      "region"       = "us-east-1"
      "role_arn"     = "arn:aws:iam::555555555:role/sym/SymSSOTenant-Foo"
    }
    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-999999/ps-9999999"
    target_account_id  = "8888888"
  },
}
```

## Modules

### tenant-foo-connector module

This module could be used to provision SSO Connectors per tenant AWS Organization. We do not include it automatically because the assumption is that provisioning this module should be done separately from provisioning the main Sym flow configurations in the host AWS Organization.

### sso_flow module

This module allows you to use the same basic configuration approach for all the tenant access flows, while exposing the required differences for each tenant organization.

Our example intentionally keeps the configuration of Permission Sets and Account IDs very simple. You can update the module to specify a list of Permission Set/Account ID pairs if necessary.

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
