import requests
from sym.sdk.annotations import hook, reducer
from sym.sdk.integrations import slack


# Reducers fill in the blanks that your workflow needs in order to run.
@reducer
def get_approvers(event):
    """Route Sym requests to a channel specified in the sym_flow."""

    flow_vars = event.flow.vars
    return slack.channel(flow_vars["request_channel"], allow_self=True)


def fetch_circle_ci_jobs(session, workflow_id):
    """Get all jobs in the workflow"""
    response = session.get(f"https://circleci.com/api/v2/workflow/{workflow_id}/job")
    return response.json()


def approve_circle_ci_hold(session, workflow_id, approval_request_id):
    """Post request to approve CircleCI hold job"""
    response = session.post(
        f"https://circleci.com/api/v2/workflow/{workflow_id}/approve/{approval_request_id}"
    )
    return response.json()


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
def on_approve(event):
    workflow_id = event.payload.fields.get("workflow_id")

    with requests.Session() as session:
        session.headers.update(circleci_authentication_header(event))

        job_list = fetch_circle_ci_jobs(session, workflow_id)

        circle_approval_step = [
            d["id"] for d in job_list["items"] if d["name"] == "wait_for_sym_approval"
        ]
        circle_approval_step_id = circle_approval_step[0] if circle_approval_step else None

        approve_circle_ci_hold(session, workflow_id, circle_approval_step_id)