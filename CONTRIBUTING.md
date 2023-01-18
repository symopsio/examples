# Creating a New Example
This repo contains folders of end-to-end examples containing the minimally necessary Terraform and `impl.py` files to configure a specific Flow.

This document describes a set of steps for how to create a structurally consistent example.

## Structure
- An example should be tightly scoped to the feature it is exemplifying.
- If possible, there should only be one `main.tf` containing the entire Terraform configuration.
- Each example should be contained in its own folder, named with underscores (i.e. `okta_access_strategy`)

### Files
  - `README.md` should have:
	  - A title with a descriptor of the example, e.g. `Okta Access Strategy`.
	  - 1-2 sentence description of what the Flow does.
	  - A short screen recording, if possible.
	  - See the [`okta_access_strategy/README.md`](basic/okta_access_strategy/README.md) for an example.
  - `impl.py`
	  - The minimal `impl.py` needed for the example to run.
  - `main.tf`
	  - The minimal Terraform needed to configure the Flow.
		  - If the file exceeds 300 lines, then you can consider breaking it up into multiple files.
  - `versions.tf`
	  - The minimally required providers for the example.

## Constructing an Example
### Implementing
- Implement your example in a new folder
- Add a README.md. You can use the `basic/approvals` README.md as a template
- Add a screen recording to your example's README.md
- Run `terraform fmt`
- Commit your example

### Update the top-level README.md
- Add a row to the Content table in the root directory's [README.md](README.md).
- Make sure the table is in alphabetical order (i.e. the same order as the folders).

### Tips & Recommendations
- Avoid variables unless they are absolutely necessary, this helps make examples easily understandable at a glance.
- Comment each resource describing what it does.
- Structure the order of the resources so that if `resource-A` references `resource-B`, then `resource-B` is declared first.
    - e.g. if `sym_integration` needs a `sym_secret`, the `sym_secret` should be declared first.
- Recommended order of resources:
    - AWS Secrets Manager resources
    - Secrets & Sym Integrations
    - Access Targets
    - Access Strategy
    - Flow
    - Basic Environment Configuration
- Local Testing:
  - `override.tf` files are special Terraform files that override `main.tf`. This file is gitignored
  - `main.tf` should be written with everything you intend to commit in the example, and if you need to override something, redefine it in `override.tf` and change what needs to be changed.
  - For example:
```hcl
# main.tf
resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

  # For your main.tf, use an example Workspace ID
  external_id = "T123ABC"
}
```

```hcl
# override.tf
resource "sym_integration" "slack" {
  type = "slack"
  name = "main-slack"

  # In override.tf, use your actual workspace ID
  external_id = "T0123DCL4WW"
}
```
