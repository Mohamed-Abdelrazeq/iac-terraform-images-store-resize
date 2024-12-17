provider "aws" {
  region  = "eu-west-3"
  profile = "default"
}

# Create IAM role for Lambda
resource "aws_iam_role" "my_lambda_role" {
  name = "my_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Create S3 Images Bucket 
resource "aws_s3_bucket" "uploaded-images" {
  bucket = "mo-original-uploaded-images"
}

# Create Lambda function
resource "aws_lambda_function" "my_lambda" {
  function_name    = "my_lambda"
  handler          = "bootstrap"
  runtime          = "provided.al2"
  role             = aws_iam_role.my_lambda_role.arn
  filename         = "lambda.zip"
  architectures    = ["arm64"]
  source_code_hash = filebase64sha256("lambda.zip")
  environment {
    variables = {
    "BUCKET_NAME" : aws_s3_bucket.uploaded-images.bucket
    }
  }
}

resource "aws_s3_bucket_versioning" "uploaded-images" {
  bucket = aws_s3_bucket.uploaded-images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create policy to allow lambda to put object into s3 
resource "aws_iam_policy" "s3_put_object_policy" {
  name        = "s3_put_object_policy"
  description = "Policy to allow Lambda to put objects in S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
                    "s3:PutObjectAcl" 
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.uploaded-images.arn}/*"]
      }
    ]
  })
}

# Attach policy to Lambda role to allow putting objects in S3
resource "aws_iam_role_policy_attachment" "lambda_s3_put_object" {
  role       = aws_iam_role.my_lambda_role.name
  policy_arn = aws_iam_policy.s3_put_object_policy.arn
}

# Create REST API Gateway
resource "aws_api_gateway_rest_api" "upload-api" {
  name               = "upload-image-api"
  binary_media_types = ["*/*"]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Create REST API Gateway Resource
resource "aws_api_gateway_resource" "upload-api" {
  parent_id   = aws_api_gateway_rest_api.upload-api.root_resource_id
  path_part   = "image"
  rest_api_id = aws_api_gateway_rest_api.upload-api.id
}

# Create REST API Gateway Method
resource "aws_api_gateway_method" "upload-api" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.upload-api.id
  rest_api_id   = aws_api_gateway_rest_api.upload-api.id
  request_models = {
    "application/json" = "Empty"
  }
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "upload-api" {
  http_method             = aws_api_gateway_method.upload-api.http_method
  resource_id             = aws_api_gateway_resource.upload-api.id
  rest_api_id             = aws_api_gateway_rest_api.upload-api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda.invoke_arn
  content_handling        = "CONVERT_TO_BINARY"
}

# Create API Gateway Request Validator
resource "aws_api_gateway_request_validator" "upload-api" {
  rest_api_id                 = aws_api_gateway_rest_api.upload-api.id
  name                        = "validate-content-type"
  validate_request_parameters = true
}

# Create API Gateway Deployment
resource "aws_api_gateway_deployment" "upload-api" {
  depends_on  = [aws_api_gateway_integration.upload-api]
  rest_api_id = aws_api_gateway_rest_api.upload-api.id
    lifecycle {
    create_before_destroy = true
  }
    triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.upload-api.body))
  }
}

# Create API Gateway Stage
resource "aws_api_gateway_stage" "upload-api" {
  deployment_id = aws_api_gateway_deployment.upload-api.id
  rest_api_id   = aws_api_gateway_rest_api.upload-api.id
  stage_name    = "prod"
}

# Add permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.upload-api.execution_arn}/*/*"
}