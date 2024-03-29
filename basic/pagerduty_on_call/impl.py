from sym.sdk.annotations import hook, reducer
from sym.sdk.exceptions import SymException
from sym.sdk.integrations import pagerduty, slack
from sym.sdk.templates import ApprovalTemplate
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
def on_request(event):
    """If the requester is on-call, auto-approve their requests"""
    try:
        if pagerduty.is_on_call(event.user):
            original_reason = event.payload.fields["reason"]
            return ApprovalTemplate.approve(reason=f"Auto-approved On-call engineer: {original_reason}️")
    except SymException as e:
        # Catch any exceptions, such as an expired PagerDuty Token.
        # Skip auto-approval and report the error to the error channel.
        slack.send_message(
            slack.channel("#sym-requests"),
            f"A PagerDutyError occurred while checking who's on-call. Falling back to off-call behavior.\n{e}",
        )
