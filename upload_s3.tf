resource "aws_s3_bucket" "uploaded-images" {
  bucket = "mo-original-uploaded-images"
}

resource "aws_s3_bucket_versioning" "uploaded-images" {
  bucket = aws_s3_bucket.uploaded-images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add S3 bucket notification to send events to SQS queue
resource "aws_s3_bucket_notification" "uploaded_images_notification" {
  bucket = aws_s3_bucket.uploaded-images.id

  queue {
    queue_arn     = aws_sqs_queue.resizing_queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}

