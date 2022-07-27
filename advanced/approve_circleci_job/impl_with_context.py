import requests

# import time

from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack
from sym.sdk.templates import ApprovalTemplate


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a specified channel."""

    return slack.channel("#circleci-deploys")


def find_circleci_approval_job(session, workflow_id):
    """Get the first paused or blocked approval job in the given CircleCI workflow"""
    response = session.get(f"https://circleci.com/api/v2/workflow/{workflow_id}/job")
    body = response.json()
    if not response.ok:
        message = body.get("message", "")
        raise RuntimeError(f"Unable to find jobs for workflow: {message}")

    for job in body.get("items", []):
        if job["type"] == "approval" and job["status"] in ["on_hold", "blocked"]:
            return job

    raise RuntimeError(f"No on hold approval found for workflow: {workflow_id}")


def approve_circleci_job(session, workflow_id, job_id):
    """Post request to approve CircleCI hold job"""
    response = session.post(
        f"https://circleci.com/api/v2/workflow/{workflow_id}/approve/{job_id}"
    )
    body = response.json()
    if not response.ok:
        message = body.get("message", "")
        raise RuntimeError(f"Unable to approve job: {message}")
    return body


def circleci_authentication_header(event):
    """
    Grabs the Circle CI API Token from the environment integrations
    block (defined as circleci_id in the sym_environment Terraform resource)
    """
    integration = event.flow.environment.integrations["circleci"]
    token = integration.settings["secrets"][0].retrieve_value()

    if not token:
        raise RuntimeError("CircleCI API key must be set as secret 0 in Terraform")

    return {"Circle-Token": token}


@hook
def on_request(event):
    context = event.get_context("request")
    diff = context.get("diff.txt", "")
    if not "terraform" in diff:
        return ApprovalTemplate.approve(reason="No terraform changes, auto approved!")


@hook
def on_approve(event):
    workflow_id = event.payload.fields.get("workflow_id")
    if not workflow_id:
        raise ValueError("Missing workflow id")

    with requests.Session() as session:
        # Include the Circle CI Token in all subsequent requests
        session.headers.update(circleci_authentication_header(event))

        # Get the approval job from the workflow
        circleci_approval_job = find_circleci_approval_job(session, workflow_id)

        # Resume the CircleCI workflow by approving the paused job
        approve_circleci_job(session, workflow_id, circleci_approval_job["id"])
