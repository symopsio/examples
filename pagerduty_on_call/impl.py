from sym.sdk.annotations import hook, reducer
from sym.sdk.exceptions import SymException
from sym.sdk.integrations import pagerduty, slack
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themself, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)


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
