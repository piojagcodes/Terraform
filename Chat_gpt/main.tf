provider "aws" {
  region = "us-east-1"  # Zmień na odpowiednią region
}

resource "aws_lambda_function" "example" {
  filename      = "lambda_function.zip"
  function_name = "example_lambda_function"
  role          = aws_iam_role.example.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = 300

  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_iam_role" "example" {
  name = "example_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws
