from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack
from sym.sdk.notifications import Notification


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_request_notifications(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    return [Notification(destinations=[slack.channel("#sym-requests")])]

# TODO: Add a get_permissions reducer that only sets allow_self=True