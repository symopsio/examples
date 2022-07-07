# Creating a New Example
This repo contains folders of end-to-end examples containing the minimally necessary Terraform and `impl.py` files to configure a specific Flow.

This document describes a set of steps for how to create a structurally consistent example.

## Structure
- An example should be as tightly scoped to the feature it is exemplifying.
- If possible, there should only be one `main.tf` containing the entire Terraform configuration.
- Each example should be contained in its own folder, named with underscores (i.e. `okta_access_strategy`)

### Files
  - `README.md` should have:
	  - A title with a descriptor of the example, e.g. `Okta Access Strategy`.
	  - 1-2 sentence description of what the Flow does.
	  - A link to a Diff that compares wth the basic Approval Flow (instructions below).
	  - A short screen recording, if possible.
	  - See the [`okta_access_strategy/README.md`](https://github.com/symopsio/examples/blob/main/okta_access_strategy/README.md) for an example.
  - `impl.py`
	  - The minimal `impl.py` needed for the example to run.
  - `main.tf`
	  - The minimal Terraform needed to configure the Flow.
		  - If the file exceeds 300 lines, then you can consider breaking it up into multiple files.
  - `versions.tf`
	  - The minimally required providers for the example.

## Constructing an Example
### Implementing & Creating the Diff Link
In order to create a linked Diff for the README, you will need a commit containing just the basic approval, and the commit after you have implemented your example.
You can do this with:
1. `git cherry-pick 45d946e1f939032fec5bc1d55988f5e438c7b733
	- (This commit is from the [approval-base](https://github.com/symopsio/examples/tree/approval-base) branch)
2. Rename the `approval-base` folder to your example folder name (e.g. `okta_access_strategy`)
3. Update the README title and description
4. `git commit --amend --all`
5. Implement your example
6. Run `terraform fmt`
7. Commit your example
8. Create a Diff link with  `https://github.com/symopsio/examples/compare/[first_commit_hash]...[commit_hash_after_implementing]`
	- For example: https://github.com/symopsio/quickstarts/compare/9f6aedea...2232a9f
	- (Note: You can use short hashes or long hashes, they both work)

### Update the example README.md
1. Update your example's README.md with the Diff link after you have finished implementing.
2. Update your example's README.md with a screen recording.

### Update the Top-level README.md
- Add a row to the Content table in the root directory's [README.md](https://github.com/symopsio/examples/blob/main/README.md).
- Make sure the table is in alphabetical order (i.e. the same order as the folders).

### Tips & Recommendations
- Avoid variables unless they are absolutely necessary, this helps make examples easily understandable at a glance.
- Comment each resource describing what it does.
- Structure the order of the resources so that if `resource-A` references `resource-B`, then `resource-A` is declared first.
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
