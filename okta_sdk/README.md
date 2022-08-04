# Okta SDK

This example illustrates how to use the Okta SDK in your Sym Flow implementation.

## Configuring the on_approve hook ##

The Flow implementation declares an [`on_approve`](https://docs.symops.com/docs/hooks#on_approve) hook that checks if the approving user is in a given Okta Group before allowing the approval to continue.

You need to specify a valid Okta Group ID in your `flow_vars` to complete the setup:

```
resource "sym_flow" "this" {
  ...
  vars = {
    approvers_group = "00g123456789"
  }
  ...
}

## Using profile data ##

The Flow implementation routes requests to different channels depending on what department the requesting user is in. We access the department using the Sym Okta Integration's [`get_user_info`](https://sdk.docs.symops.com/doc/sym.sdk.integrations.okta.html#sym.sdk.integrations.okta.get_user_info) API to get the user's Okta profile data.

## More info

Refer to the [Okta SDK docs](https://docs.symops.com/docs/okta-sdk-integration) for more info.

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
