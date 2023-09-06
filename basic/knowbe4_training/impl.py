from sym.sdk.annotations import hook, reducer
from sym.sdk.exceptions import SymException
from sym.sdk.integrations import knowbe4, slack
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    # allow_self lets the requester approve themselves, which is great for testing!
    return slack.channel("#sym-requests", allow_self=True)

@hook
def on_request(event):
    try:
        # Returns a list of all training enrollments filtered by the user, store purchase and training campaign.
        # Store purchases are the training content bought from ModStore
        # Training campaigns enable selecting content that users will see in their Learner Experience
        if knowbe4.get_training_enrollments_for_user(event.user, store_purchase_id=209465, campaign_id=100345)[0]["status"] == "Passed":
            # If the training has been completed, then auto-approve their requests
            return ApprovalTemplate.approve()
    except SymException as e:
        # Catch any exceptions, such as 5xx error returned by KnowBe4 API
        # Skip auto-approval and report the error to the error channel.
        slack.send_message(
            slack.channel("#sym-requests"),
            f"A KnowBe4Error occurred while fetching training enrollments for user.\n{e}",
        )
