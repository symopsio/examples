from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack, aws_lambda


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)


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
