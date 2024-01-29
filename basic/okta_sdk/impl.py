from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import okta, slack
from sym.sdk.templates import ApprovalTemplate
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """Decide who can see and take actions on requests."""

    department = get_user_department(event.user)
    engineering_managers_okta_group_id = "00g12345"
    other_managers_okta_group_id = "00g9876"

    if department == "engineering":
        approve_deny = user_ids(okta.users_in_group(group_id=engineering_managers_okta_group_id))
    else:
        approve_deny = user_ids(okta.users_in_group(group_id=other_managers_okta_group_id))

    return RequestPermission(
        # Only admins may view this request in Sym's web app.
        webapp_view=PermissionLevel.ADMIN,
        # Depending on the department use Slack channels to manage what users can approve or deny requests.
        approve_deny=approve_deny,
        # allow_self_approval lets users approve their own requests. This is great for testing!
        allow_self_approval=True
    )

@reducer
def get_request_notifications(event):
    """Decide where notifications about new requests are sent."""

    notifications = []
    department = get_user_department(event.user)
    if department == "engineering":
        # Send new Sym requests to the #eng-requests Slack channel.
        notifications.append(Notification(destinations=[slack.channel("#eng-requests")]))
    else:
        # Send new Sym requests to the #sym-requests Slack channel.
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
