resource "aws_sqs_queue" "resizing_queue" {
    name = "resizing_queue"
    policy = data.aws_iam_policy_document.send_s3_events_to_sqs.json
}
