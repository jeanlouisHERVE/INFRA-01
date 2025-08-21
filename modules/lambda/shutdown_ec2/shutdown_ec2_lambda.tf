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
  timeout          = 30

  environment {
    variables = {
      ENVIRONMENT = "DEV"
    }
  }

  tags = {
    Application = "shutdown-ec2"
    Environment = "production"
  }
}

#################################20PMUTC#################################
# CloudWatch rule for nightly execution
resource "aws_cloudwatch_event_rule" "shutdown_ec2_20UTC" {
  name                = "shutdown_ec2_evening"
  schedule_expression = "cron(0 20 * * ? *)" # Every night at 8 PM UTC
}

# Attach Lambda to CloudWatch rule
resource "aws_cloudwatch_event_target" "shutdown_ec2_lambda_20UTC_target" {
  rule      = aws_cloudwatch_event_rule.shutdown_ec2_20UTC.name
  target_id = "ShutdownEC2Lambda"
  arn       = aws_lambda_function.shutdown_ec2_lambda.arn
}

# Grant CloudWatch Events permission to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_20UTC" {
  statement_id  = "AllowExecutionFromCloudWatch20UTC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_ec2_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_ec2_20UTC.arn
}

#################################06AMUTC#################################
# CloudWatch rule for nightly execution
resource "aws_cloudwatch_event_rule" "shutdown_ec2_6UTC" {
  name                = "shutdown_ec2_earlymorning"
  schedule_expression = "cron(0 6 * * ? *)" # Every night at 6 AM UTC
}

# Attach Lambda to CloudWatch rule
resource "aws_cloudwatch_event_target" "shutdown_ec2_lambda_6UTC_target" {
  rule      = aws_cloudwatch_event_rule.shutdown_ec2_6UTC.name
  target_id = "ShutdownEC2Lambda"
  arn       = aws_lambda_function.shutdown_ec2_lambda.arn
}

# Grant CloudWatch Events permission to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_6UTC" {
  statement_id  = "AllowExecutionFromCloudWatch6UTC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_ec2_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_ec2_6UTC.arn
}