variable "datadog_access_key" {
  description = "Secret used by the Firehose to send logs to Datadog. DO NOT check this into version control."
  type        = string
  sensitive   = true
}
