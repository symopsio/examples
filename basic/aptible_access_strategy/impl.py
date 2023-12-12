from sym.sdk.annotations import reducer
from sym.sdk.integrations import slack
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """allow_self lets the requester approve themself, which is great for testing!"""
    return RequestPermission(
        webapp_view=PermissionLevel.ADMIN,
        approve_deny=PermissionLevel.MEMBER,
        allow_self_approval=True
    )

@reducer
def get_request_notifications(event):
    """Route Sym requests to the sym-requests slack channel"""

    return [Notification(destinations=[slack.channel("#sym-requests")])]