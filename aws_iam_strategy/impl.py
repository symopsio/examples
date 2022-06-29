from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)
