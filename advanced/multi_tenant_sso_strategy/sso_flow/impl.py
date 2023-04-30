from sym.sdk.annotations import reducer, hook
from sym.sdk.integrations import slack


# Reducers fill in the blanks that your workflow needs in order to run.
# For more information, please see https://docs.symops.com/docs/reducers
@reducer
def get_approvers(event):
    """Route Sym requests to a specified channel."""

    # Make sure that this channel has been created in your workspace!
    return slack.channel("#sym-requests", allow_self=True)
