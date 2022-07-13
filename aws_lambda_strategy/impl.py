from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack
from sym.sdk.templates import get_step_output


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)


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
