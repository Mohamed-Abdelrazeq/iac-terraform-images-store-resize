resource "aws_s3_bucket" "resized-images" {
  bucket = "mo-resized-uploaded-images"
}

resource "aws_s3_bucket_versioning" "resized-images" {
  bucket = aws_s3_bucket.resized-images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# TODO: Add S3 bucket notification to send events to SQS queue to notify the users when the image is resized
# resource "aws_s3_bucket_notification" "_images_notification" {
#   bucket = aws_s3_bucket.uploaded-images.id

#   queue {
#     queue_arn     = aws_sqs_queue.resizing_queue.arn
#     events        = ["s3:ObjectCreated:*"]
#   }
# }

