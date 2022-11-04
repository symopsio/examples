from sym.sdk.annotations import reducer, prefetch
from sym.sdk.integrations import slack
from sym.sdk.field_option import FieldOption
import requests


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)


# Prefetch reducers return a list of FieldOptions that will be used to populate
# the Slack select menu for the Prompt Field with the given "field_name"
@prefetch(field_name="repo_name")
def get_repos(event):
    github_token = event.flow.environment.integrations["github"].settings["api_token_secret"].retrieve_value()
    headers = {"Authorization": f"Token {github_token}"}

    # Use the GitHub API to get the first 100 public repos in the Symopsio organization
    response = requests.get(
        url="https://api.github.com/orgs/symopsio/repos?per_page=100&type=public",
        headers=headers
    )
    if not response.ok:
        raise RuntimeError(f"Failed to query repos from GitHub. Status code: {response.status_code}.")

    # For this example, the value and the label are the same for the options.
    # Return a list of all the repos in the API response.
    return [
        FieldOption(value=repo["name"], label=repo["name"]) for repo in response.json()
    ]
