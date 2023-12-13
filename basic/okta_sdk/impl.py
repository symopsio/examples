from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import okta, slack
from sym.sdk.templates import ApprovalTemplate
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """
    approve_deny is set here to allow only the users in the sym-requests slack channel to approve or deny a request
    allow_self lets the requester approve themself, which is great for testing!
    """
    department = get_user_department(event.user)
    approve_deny = slack.users_in_channel("#sym-requests")
    if department == "engineering":
        approve_deny = slack.users_in_channel("#eng-requests")

    return RequestPermission(
        webapp_view=PermissionLevel.ADMIN,
        approve_deny=approve_deny,
        allow_self_approval=True
    )

@reducer
def get_request_notifications(event):
    """Send Sym requests to the sym-requests slack channel"""
    notifications = []
    department = get_user_department(event.user)
    if department == "engineering":
        notifications.append(Notification(destinations=[slack.channel("#eng-requests")]))
    else:
        notifications.append(Notification(destinations=[slack.channel("#sym-requests")]))

    return notifications


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
