def lambda_handler(event, context):
    # The full structure of the Payload sent is described in the Sym Docs:
    # https://docs.symops.com/docs/aws-lambda#payload
    print(event)

    event_type = event["event"]["type"]
    requester = event["run"]["actors"]["request"]["username"]

    # This Lambda is invoked for both escalate and de-escalate, so we must branch logic based on the event type.
    if event_type == "escalate":
        return grant_access(requester)
    elif event_type == "deescalate":
        return remove_access(requester)


def grant_access(requester):
    if is_human(requester):
        # ... some custom escalate logic ...

        # The AWS Lambda Strategy enforces a specific response body format.
        # It must contain two top-level keys `body` and `errors`
        return {
            # A JSON-object containing whatever values you wish to pass back to your `impl.py`.
            # These values can be retrieved with `get_step_output("escalate")` and `get_step_output("deescalate")`
            "body": {
                "message": (
                    "You've been granted access to the super secret Aperture Science Heavy Duty Super-Colliding Super Button! "
                    "Access it here: https://www.valvearchive.com/web_archive/aperturescience.com/2007-10-17.html"
                )
            },

            # A list of errors encountered while executing your Lambda.
            # If this is non-empty, then the Request will be marked as "errored" and the error messages
            # will be sent to the configured error channel.
            "errors": []
        }
    else:
        return {
            "body": {},

            # This error message will be sent to the error channel.
            "errors": ["Access Denied: Humans Only!"]
        }


def remove_access(requester):
    # ... some custom de-escalate logic ...
    return {
        "body": {
            "message": f"{requester}, your access to the super secret Aperture Science Heavy Duty Super-Colliding Super Button has ended"
        },
        "errors": []
    }


def is_human(username):
    return username.lower() != "glados"
