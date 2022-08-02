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


def api_request(api_path, integration, params={}):
    """
    Hit the given path in the VictorOps API using our custom integration.
    For details on the API format:
    https://portal.victorops.com/public/api-docs.html
    """

    # Get the api key we passed in to the integration with the secret_ids_json setting
    token = integration.settings["secrets"][0].retrieve_value()

    headers = {
        "Accept": "application/json",
        # We used the API ID as our custom integration's external ID
        "X-VO-Api-Id": integration.external_id,
        "X-VO-Api-Key": token,
    }
    response = requests.get(
        f"https://api.victorops.com/api-public/{api_path}",
        headers=headers,
        params=params,
    )
    body = response.json()

    if not response.ok:
        message = body.get("message", "")
        raise RuntimeError(f"API failed with message: {message}")

    return body


def find_user_by_email(email, integration):
    """Hit the VictorOps API to find the username for the given email"""
    response = api_request("v2/user", integration, params={"email": email})
    for user in response.get("users", []):
        return user["username"]


def get_custom_user(user, integration):
    """
    Get the VictorOps username for the given Sym user. Each Sym user may have a separate identity
    stored for each integrated service.

    If the user already has a VictorOps identity, then return it.
    Otherwise, fetch the identity from VictorOps and persist it.

    Note: You can also use the symflow CLI to custom map user identities if necessary.
    """
    identity = user.identity("custom", integration.external_id)
    if identity:
        return identity.user_id

    user_id = find_user_by_email(user.email, integration)
    if user_id:
        # Use the Sym SDK to store the user identity so we don't need to look it up again.
        persist_user_identity(
            email=user.email,
            service="custom",
            service_id=integration.external_id,
            user_id=user_id,
        )

    return user_id


def is_requester_on_call(event):
    """Check if the requesting user is currently on call in VictorOps using our custom
    integration"""

    # Get the custom integration we set up for VictorOps
    integration = event.flow.environment.integrations["victorops"]

    # Get the VictorOps username for the given Sym user. If they don't have a VictorOps
    # username, then they're not on call!
    username = get_custom_user(event.user, integration)
    if not username:
        return False

    # See if the user is on call
    on_call_response = api_request("v1/oncall/current", integration)
    for team in on_call_response.get("teamsOnCall", []):
        for oncall in team["oncallNow"]:
            for user in oncall["users"]:
                if user["onCalluser"]["username"] == username:
                    return True
