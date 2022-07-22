import requests
from requests.exceptions import RequestException
from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import pagerduty, slack
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)


# Hooks let you customize workflow behavior running code before or after each
# step in your workflow.
@hook
def on_request(event):
    """If the requester is on-call, auto-approve their requests"""
    try:
        if is_requester_on_call(event):
            original_reason = event.payload.fields["reason"]
            return ApprovalTemplate.approve(
                reason=f"Auto-approved On-call engineer: {original_reason}️"
            )
    except (RuntimeError, RequestException) as e:
        # Catch any exceptions, such as an expired API Token.
        # Skip auto-approval and report the error to the error channel.
        print(
            f"An error occurred while checking who's on-call. Falling back to off-call behavior.\n{e}"
        )


def get_teams_on_call(integration):
    """Use the custom integration to hit the VictorOps API to retrieve on call users"""

    # Get the api key we passed in to the integration with the secret_ids_json setting
    token = integration.settings["secrets"][0].retrieve_value()

    # For details on the oncall API format:
    # https://portal.victorops.com/api-docs/#!/On45call/get_api_public_v1_oncall_current
    headers = {
        "Accept": "application/json",
        # We used the API ID as our custom integration's external ID
        "X-VO-Api-Id": integration.external_id,
        "X-VO-Api-Key": token,
    }
    response = requests.get(
        "https://api.victorops.com/api-public/v1/oncall/current", headers=headers
    )
    body = response.json()

    if not response.ok:
        message = body.get("message", "")
        raise RuntimeError(f"API failed with message: {message}")

    return body.get("teamsOnCall", [])


def is_requester_on_call(event):
    """Check if the requesting user is currently on call in VictorOps using our custom
    integration"""

    # Get the custom integration we set up for VictorOps
    integration = event.flow.environment.integrations["victorops"]
    teams_on_call = get_teams_on_call(integration)

    # Each Sym user has a separate identity stored for each integrated service.
    # Get the VictorOps username associated with the Sym user.
    requester_id = event.user.identity("custom", integration.external_id).user_id

    for team in teams_on_call:
        for oncall in team["oncallNow"]:
            for user in oncall["users"]:
                if user["onCalluser"]["username"] == requester_id:
                    return True
