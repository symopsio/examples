#customer_tenants = {
#  tenant_foo = {
#    sso_account_id = "1234567890"
#    sso_connector_settings = {
#      "cloud"        = "aws"
#      "instance_arn" = "arn:aws:sso:::instance/ssoins-000000"
#      "region"       = "us-east-1"
#      "role_arn"     = "arn:aws:iam::1234567890:role/sym/SymSSOTenant-Foo"
#    }
#    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-000000/ps-000000"
#    target_account_id  = "333333333"
#  },
#  tenant_bar = {
#    sso_account_id = "555555555"
#    sso_connector_settings = {
#      "cloud"        = "aws"
#      "instance_arn" = "arn:aws:sso:::instance/ssoins-1111111"
#      "region"       = "us-east-1"
#      "role_arn"     = "arn:aws:iam::555555555:role/sym/SymSSOTenant-Foo"
#    }
#    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-999999/ps-9999999"
#    target_account_id  = "8888888"
#  },
#}

customer_tenants = {
  ingen = {
    sso_account_id = "104924364283"
    sso_connector_settings = {
      "cloud"        = "aws"
      "instance_arn" = "arn:aws:sso:::instance/ssoins-722378d559a93a9a"
      "region"       = "us-east-1"
      "role_arn"     = "arn:aws:iam::104924364283:role/sym/SymSSOIngen-Sso"
    }
    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-722378d559a93a9a/ps-211ff20d07ba62f6"
    target_account_id  = "991756738365"
  },
  sym = {
    sso_account_id = "105240470752"
    sso_connector_settings = {
      "cloud"        = "aws"
      "instance_arn" = "arn:aws:sso:::instance/ssoins-72231fda92423e7f"
      "region"       = "us-east-1"
      "role_arn"     = "arn:aws:iam::105240470752:role/sym/SymSSOSym-Sso"
    }
    permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-72231fda92423e7f/ps-2ef7e08d6183989c"
    target_account_id  = "105240470752"
  },
}
