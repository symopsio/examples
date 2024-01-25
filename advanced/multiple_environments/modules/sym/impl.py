from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack
from sym.sdk.templates import ApprovalTemplate
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """Decide who can see and take actions on requests."""

    flow_vars = event.flow.vars

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

    flow_vars = event.flow.vars

    # Send new Sym requests to a channel specified in the sym_flow in Terraform.
    return [Notification(destinations=[slack.channel(flow_vars["request_channel"])])]


# Hooks let you change the control flow of your workflow.
@hook
def on_approve(event):
    """Only let members of the approver safelist approve requests."""

    if not has_approve_access(event):
        return ApprovalTemplate.ignore(
            message="You are not authorized to approve this request."
        )


@hook
def on_deny(event):
    """Only let members of the approve safelist or the original requester
    deny requests.
    """

    requester = event.get_actor("request")
    if not (requester == event.user or has_approve_access(event)):
        return ApprovalTemplate.ignore(
            message="You are not authorized to deny this request."
        )


def has_approve_access(event):
    """Check if the requesting user is in the safelist, defined in the sym_flow."""

    flow_vars = event.flow.vars
    approvers = flow_vars["approvers"].split(",")
    return event.user.username in approvers
