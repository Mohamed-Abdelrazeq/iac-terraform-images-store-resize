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
  uri                     = aws_lambda_function.upload_lambda.invoke_arn
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