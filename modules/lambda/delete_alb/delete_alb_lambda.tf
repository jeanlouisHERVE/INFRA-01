data "aws_iam_policy_document" "alb_cleanup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "alb_cleanup_lambda_role" {
  name               = "alb_cleanup_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.alb_cleanup_assume_role.json
}

resource "aws_iam_role_policy" "alb_cleanup_lambda_policy" {
  name = "alb_cleanup_policy"
  role = aws_iam_role.alb_cleanup_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteListener"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "alb_cleanup_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/alb_cleanup.py"
  output_path = "${path.module}/alb_cleanup_lambda.zip"
}

resource "aws_lambda_function" "alb_cleanup_lambda" {
  filename         = data.archive_file.alb_cleanup_lambda_zip.output_path
  function_name    = "alb_cleanup_lambda"
  role             = aws_iam_role.alb_cleanup_lambda_role.arn
  handler          = "alb_cleanup.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.alb_cleanup_lambda_zip.output_base64sha256
  timeout          = 60

  environment {
    variables = {
      ENVIRONMENT = "DEV"
    }
  }

  tags = {
    Application = "alb-cleanup"
    Environment = "production"
  }
}

resource "aws_cloudwatch_event_rule" "alb_cleanup_22UTC" {
  name                = "alb_cleanup_nightly"
  schedule_expression = "cron(0 22 * * ? *)" # Every night at 22:00 UTC
}

resource "aws_cloudwatch_event_target" "alb_cleanup_lambda_22UTC_target" {
  rule      = aws_cloudwatch_event_rule.alb_cleanup_22UTC.name
  target_id = "AlbCleanupLambda"
  arn       = aws_lambda_function.alb_cleanup_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_22UTC" {
  statement_id  = "AllowExecutionFromCloudWatch22UTC"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_cleanup_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alb_cleanup_22UTC.arn
}