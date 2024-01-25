from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack, aws_lambda
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


# Hooks let you change the control flow of your workflow.
@hook
def on_request(event):
    """Synchronously invoke your AWS lambda."""
    lambda_arn = event.flow.vars["lambda_arn"]
    response = aws_lambda.invoke(lambda_arn, {"event": "on_request", "email": event.user.email})
    print(f"Invoked {lambda_arn} synchronously! Response:")
    print(response)


@hook
def after_request(event):
    """Asynchronously invoke your AWS lambda."""
    lambda_arn = event.flow.vars["lambda_arn"]
    aws_lambda.invoke_async(lambda_arn, {"event": "after_request", "email": event.user.email})
    print(f"Invoked {lambda_arn} asynchronously!")
