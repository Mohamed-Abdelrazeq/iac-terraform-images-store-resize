# Create IAM role for Lambda
resource "aws_iam_role" "resized_lambda_role" {
  name = "resize-lambda-role"

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

# Create policy to allow lambda to put object into s3 
resource "aws_iam_policy" "s3_read_put_object_policy" {
  name        = "s3_read_put_object_policy"
  description = "Policy to allow Lambda to read objects from S3 bucket and put them in another S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.uploaded-images.arn}/*"]
      },
          {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl", 
        ]
        Effect   = "Allow"
        # Allow Lambda to put objects in the resized-images bucket
        Resource = ["${aws_s3_bucket.resized-images.arn}/*"]
      }
    ]
  })
}

# Attach policy to Lambda role to allow putting objects in S3
resource "aws_iam_role_policy_attachment" "lambda_s3_read_put_object" {
  role       = aws_iam_role.resized_lambda_role.name
  policy_arn = aws_iam_policy.s3_read_put_object_policy.arn
}