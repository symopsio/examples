from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack, aws_lambda
from sym.sdk.notifications import Notification
from sym.sdk.request_permission import PermissionLevel, RequestPermission


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_permissions(event):
    """
    approve_deny is set here to allow only the users in the sym-requests slack channel to approve or deny a request
    allow_self lets the requester approve themself, which is great for testing!
    """
    return RequestPermission(
        webapp_view=PermissionLevel.ADMIN,
        approve_deny=slack.users_in_channel("#sym-requests"),
        allow_self_approval=True
    )

@reducer
def get_request_notifications(event):
    """Route Sym requests to the sym-requests slack channel"""

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
