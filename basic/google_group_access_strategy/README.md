# Google Group Access Strategy

This example illustrates how to implement a Sym Flow that uses a Google Group Access Strategy to grant users temporary access to a Google Group.

## Manual Steps
This example requires some manual steps after applying. The `gcp_connector` module creates the resources requird for the
Sym Runtime to impersonate a service account in Google Cloud, but that service account must be granted an Admin Role
via the Google Workspace Admin Console in order to manage Google Group Memberships.

See the main documentation for instructions on [how to set up this Admin Role and grant it to the service account.](https://docs.symops.com/docs/google#allow-sym-to-manage-google-group-memberships)


## Tutorial

Check out a step-by-step tutorial [here](https://docs.symops.com/docs/google).

## About Sym

This workflow is just one example of how Sym Implementers use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/sym-access-flows).
