def lambda_handler(event, context):
    print("Hello from Sym aws_lambda!")

    return {
        "foo": "bar",
        "event": event
    }
