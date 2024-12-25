# Terraform Image Store and Resize Infrastructure

This project uses Terraform to set up an infrastructure on AWS for storing and resizing images. The infrastructure includes an S3 bucket for uploading images, an S3 bucket for storing resized images, an SQS queue for processing image resize requests, and a Lambda function to handle the resizing.

## Architecture

1. **S3 Buckets**:
   - `uploaded-images`: Stores the original uploaded images.
   - `resized-images`: Stores the resized images.

2. **SQS Queue**:
   - `resizing_queue`: Receives messages when a new image is uploaded to the `uploaded-images` bucket.

3. **Lambda Function**:
   - `resize_lambda`: Triggered by messages in the `resizing_queue` to resize images and store them in the `resized-images` bucket.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed.
- AWS CLI configured with appropriate credentials.
- An S3 bucket to store the Lambda deployment package (`lambda.zip`).

## Setup

1. **Clone the repository**:
   ```sh
   git clone https://github.com/your-repo/terraform-image-store-resize.git
   cd terraform-image-store-resize
   ```

2. **Create the Lambda deployment package:**:
    ```sh
    Create a lambda.zip file containing your Lambda function code.
    ```
    
3. **Initialize Terraform:**:
    ```sh
    terraform init
    ```

4. **Apply the Terraform configuration:**:
    ```sh
    terraform apply
    ```

## Files

- main.tf: Main Terraform configuration file.
- upload_s3.tf: Configuration for the S3 buckets.
- resize_sqs.tf: Configuration for the SQS queue.
- resize_lambda.tf: Configuration for the Lambda function.
- upload_s3_iam.tf: IAM roles and policies for S3.
- resize_lambda_iam.tf: IAM roles and policies for the Lambda function.
IAM Roles and Policies
- S3 IAM Role: Allows S3 to send messages to the SQS queue.
- Lambda IAM Role: Allows the Lambda function to read from SQS, read from the uploaded-images bucket, write to the resized-images bucket, and log to CloudWatch.

## S3 Buckets

- uploaded-images: This bucket is used to store the original images that are uploaded by users. It has versioning enabled to keep track of changes to the objects.
- resized-images: This bucket is used to store the resized versions of the images. The Lambda function writes the resized images to this bucket.

## IAM Roles and Policies

- S3 IAM Role: Allows S3 to send messages to the SQS queue. This role is assumed by the S3 service to send notifications to the SQS queue when a new image is uploaded.
- Lambda IAM Role: Allows the Lambda function to:
    -  Read from the resizing_queue SQS queue.
    -  Read from the uploaded-images S3 bucket.
    - Write to the resized-images S3 bucket.
    - Log to CloudWatch for monitoring and debugging purposes.

## Resources

- S3 Bucket Notification: Sends an event to the SQS queue when a new image is uploaded.
- SQS Queue: Receives messages from the S3 bucket.
- Lambda Function: Processes messages from the SQS queue to resize images.
- API Gateway: Connect the upload lambda function to the internet to receive requests

## License

This project is licensed under the MIT License