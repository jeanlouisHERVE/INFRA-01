# IAM assume role policy
data "aws_iam_policy_document" "shutdown_ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for Lambda
resource "aws_iam_role" "shutdown_ec2_lambda_role" {
  name               = "shutdown_ec2_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.shutdown_ec2_assume_role.json
}

# Inline policy to allow EC2 stop/describe
resource "aws_iam_role_policy" "shutdown_ec2_lambda_policy" {
  name = "shutdown_ec2_policy"
  role = aws_iam_role.shutdown_ec2_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

# Zip Python script for Lambda deployment
data "archive_file" "shutdown_ec2_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/shutdown_ec2_lambda.zip"
}

# Lambda function
resource "aws_lambda_function" "shutdown_ec2_lambda" {
  filename         = data.archive_file.shutdown_ec2_lambda_zip.output_path
  function_name    = "shutdown_ec2_lambda"
  role             = aws_iam_role.shutdown_ec2_lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.shutdown_ec2_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = "production"
    }
  }

  tags = {
    Application = "shutdown-ec2"
    Environment = "production"
  }
}

# CloudWatch rule for nightly execution
resource "aws_cloudwatch_event_rule" "shutdown_ec2_schedule" {
  name                = "shutdown_ec2_nightly"
  schedule_expression = "cron(45 18 * * ? *)" # Every night at 1 AM UTC
}

# Attach Lambda to CloudWatch rule
resource "aws_cloudwatch_event_target" "shutdown_ec2_lambda_target" {
  rule      = aws_cloudwatch_event_rule.shutdown_ec2_schedule.name
  target_id = "ShutdownEC2Lambda"
  arn       = aws_lambda_function.shutdown_ec2_lambda.arn
}

# Grant CloudWatch Events permission to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_ec2_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_ec2_schedule.arn
}