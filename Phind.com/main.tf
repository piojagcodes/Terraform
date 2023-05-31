provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "license_plate_detection" {
  function_name = "license_plate_detection"
  runtime = "python3.8"
  handler = "lambda_function.lambda_handler"
  filename = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  role = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      AWS_DEFAULT_REGION = "us-east-1"
    }
  }
  timeout = 300
}

resource "aws_s3_bucket" "bucket" {
  bucket = "bucket-name"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

resource "aws_lambda_permission" "s3_permission" {
  statement_id  = "AllowS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.license_plate_detection.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir = "lambda"
  output_path = "lambda.zip"
}

output "lambda_arn" {
  value = aws_lambda_function```
