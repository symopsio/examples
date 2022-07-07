# Tailscale SSH Access

This example illustrates how to implement a Sym Flow that uses a Tailscale Access Strategy to grant users temporary SSH access to devices.

A diff between this example and the basic [Approval](../approvals) example: [Diff](https://github.com/symopsio/examples/compare/67553549...00062b0)

## Example ACL

This example assumes your Tailnet is set up with at least the following ACL configuration, with groups for `prod` and `staging`. Each group provides SSH access to devices with a matching tag:

```json
{
    "groups": {
        "group:prod": [],
        "group:staging": []
    },
    "acls": [
        {
            "action": "accept",
            "src": ["group:prod"],
            "dst": ["tag:prod:*"]
        },
        {
            "action": "accept",
            "src": ["group:staging"],
            "dst": ["tag:staging:*"]
        }
    ],
    "ssh": [
        {
            "action": "accept",
            "src": ["group:prod"],
            "dst": ["tag:prod"],
            "users": ["ssh-user"]
        },
        {
            "action": "accept",
            "src": ["group:staging"],
            "dst": ["tag:staging"],
            "users": ["ssh-user"]
        }
    ],
    "tagOwners": {
        "tag:prod": ["group:prod"],
        "tag:staging": ["group:staging"]
    }
}

```

## About Sym

This workflow is just one example of how [Sym Implementers](https://docs.symops.com/docs/sym-for-implementers) use the [Sym SDK](https://docs.symops.com/docs) to create [Sym Flows](https://docs.symops.com/docs/flows).
