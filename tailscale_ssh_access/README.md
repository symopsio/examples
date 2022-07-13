# Tailscale SSH Access

This example illustrates how to implement a Sym Flow that uses a Tailscale Access Strategy to grant users temporary SSH access to devices.

A diff between this example and the basic [Approval](../approvals) example: [Diff](https://github.com/symopsio/examples/compare/0e957073852a414026b028b1ebfbccb16c271059...29e048598a2c549d6d78e576270484db9f51e36b)


https://user-images.githubusercontent.com/13071889/177807055-771c7690-5d3f-4973-a96e-c573ac62bfb9.mov


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
