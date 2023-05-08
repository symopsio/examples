# An AWS IAM Policy that grants the permission to publish to Kinesis Firehose Delivery Streams tagged with SymEnv
# and the perimssion to list Delivery Streams.
resource "aws_iam_policy" "aws_kinesis_firehose" {
  name = "SymKinesisFirehose${title(local.environment_name)}"
  path = "/sym/"

  description = "Addon policy granting access to Kinesis Firehose"
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "firehose:PutRecord",
        "firehose:PutRecordBatch"
      ],
      "Resource": "*",
      "Condition": { "StringEquals": { "firehose:ResourceTag/SymEnv": "${local.environment_name}" } }
    },
    {
      "Effect": "Allow",
      "Action": [
        "firehose:ListDeliveryStreams"
      ],
      "Resource": "*"
    }
  ]
}
EOT
}

# Attach the IAM policy declared above to the Runtime Connector Role output by runtime_connector
resource "aws_iam_role_policy_attachment" "aws_kinesis_firehose_attach" {
  policy_arn = aws_iam_policy.aws_kinesis_firehose.arn
  role       = module.runtime_connector.sym_runtime_connector_role.name
}
