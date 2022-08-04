from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import okta, slack
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel based on the user's Okta profile."""
    department = get_user_department(event.user)
    if department == "engineering":
        return slack.channel("#eng-requests", allow_self=True)

    return slack.channel("#sym-requests", allow_self=True)


def get_user_department(user):
    """Get the user's department from their Okta profile"""
    user_info = okta.get_user_info(user)
    return user_info.get("profile", {}).get("department", "")


# Hooks let us wrap events with additional control flow logic
@hook
def on_approve(event):
    """Require approvers to be in the Okta group defined in our flow variables."""
    if not okta.is_user_in_group(
        event.user, group_id=event.flow.vars["approvers_group"]
    ):
        return ApprovalTemplate.ignore(message="You are not an authorized approver!")
