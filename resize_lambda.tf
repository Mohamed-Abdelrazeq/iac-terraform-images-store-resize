# Create Lambda function
resource "aws_lambda_function" "resize_lambda" {
  function_name    = "resize_lambda"
  handler          = "bootstrap"
  runtime          = "provided.al2"
  role             = aws_iam_role.resized_lambda_role.arn
  filename         = "resize-lambda.zip"
  architectures    = ["arm64"]
  source_code_hash = filebase64sha256("resize-lambda.zip")
  environment {
    variables = {
      "AWS_BUCKET_NAME" : aws_s3_bucket.uploaded-images.bucket
      "AWS_RESIZED_BUCKET_NAME": aws_s3_bucket.resized-images.bucket
    }
  }
}

# Add permission to SQS to invoke Lambda function
resource "aws_lambda_permission" "allow_sqs" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.resizing_queue.arn
}

# Create event source mapping to trigger Lambda from SQS
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.resizing_queue.arn
  function_name    = aws_lambda_function.resize_lambda.arn
  batch_size       = 1
  enabled          = true
}