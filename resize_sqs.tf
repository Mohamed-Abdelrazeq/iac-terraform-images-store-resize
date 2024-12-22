resource "aws_sqs_queue" "resizing_queue" {
    name = "resizing_queue"
      policy = data.aws_iam_policy_document.queue.json
}
