from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack
from sym.sdk.templates import get_step_output
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """Decide who can see and take actions on requests."""

    return RequestPermission(
        # Only admins may view this request in Sym's web app.
        webapp_view=PermissionLevel.ADMIN,
        # Only member may approve or deny requests.
        approve_deny=PermissionLevel.MEMBER,
        # allow_self_approval lets users approve their own requests. This is great for testing!
        allow_self_approval=True
    )

@reducer
def get_request_notifications(event):
    """Decide where notifications about new requests are sent."""

    # Send new Sym requests to the #sym-requests Slack channel.
    return [Notification(destinations=[slack.channel("#sym-requests")])]


@hook
def after_escalate(event):
    # `get_step_output` defaults to current event if none is passed.
    # This is equivalent to `get_step_output("escalate")`
    output = get_step_output()

    # The output message is defined in `lambda_src/handler.py`
    slack.send_message(event.get_actor("request"), output["body"]["message"])


@hook
def after_deescalate(event):
    # This is equivalent to `get_step_output("deescalate")`
    output = get_step_output()

    # The output message is defined in `lambda_src/handler.py`
    slack.send_message(event.get_actor("request"), output["body"]["message"])
