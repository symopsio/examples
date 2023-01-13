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

    all_options = []
    per_page = 10
    page = 1

    while True:
        # Use the GitHub API to get all the private repos in the Sym Test organization (paginated)
        response = requests.get(
            url=f"https://api.github.com/orgs/sym-test/repos?per_page={per_page}&page={page}&type=private",
            headers=headers
        )

        if not response.ok:
            raise RuntimeError(f"Failed to query repos from GitHub. Status code: {response.status_code}.")

        # For this example, the value and the label are the same for the options.
        response_options = [
            FieldOption(value=repo["name"], label=repo["name"]) for repo in response.json()
        ]

        # Add all the options from the result to the total list
        all_options.extend(response_options)

        # If the total number of responses is less than our requested per_page, then there are no more results.
        if len(response_options) < per_page:
            return all_options

        # Otherwise, get the next page of results.
        page = page + 1
