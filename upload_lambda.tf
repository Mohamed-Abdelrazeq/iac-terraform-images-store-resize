# Create Lambda function
resource "aws_lambda_function" "upload_lambda" {
  function_name    = "upload_lambda"
  handler          = "bootstrap"
  runtime          = "provided.al2"
  role             = aws_iam_role.upload_lambda_role.arn
  filename         = "upload-lambda.zip"
  architectures    = ["arm64"]
  source_code_hash = filebase64sha256("upload-lambda.zip")
  environment {
    variables = {
      "BUCKET_NAME" : aws_s3_bucket.uploaded-images.bucket
    }
  }
}

# Add permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.upload-api.execution_arn}/*/*"
}