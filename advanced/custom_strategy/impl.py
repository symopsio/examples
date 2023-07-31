from sym.sdk.annotations import reducer
from sym.sdk.integrations import slack


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    return slack.channel("#sym-requests")
