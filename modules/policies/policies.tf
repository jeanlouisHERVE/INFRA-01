# IAM Policy for Grafana to access CloudWatch
resource "aws_iam_policy" "grafana_policy" {
  name        = "grafana_policy"
  description = "Allows Grafana to access CloudWatch metrics and logs and for Systems Manager access"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      #allows cloudwatch logs and metrics
      {
        Sid    = "AllowReadingMetricsFromCloudWatch",
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowReadingTagsInstancesRegionsFromEC2",
        Effect = "Allow",
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowReadingResourcesForTags",
        Effect = "Allow",
        Action = "tag:GetResources",
        Resource = "*"
      },
      {
        Sid    = "AllowDescribeLogGroups",
        Effect = "Allow",
        Action = "logs:DescribeLogGroups",
        Resource = "*"
      },
      #allow ssh 
      {
        Effect    = "Allow",
        Action    = "ssm:*",
        Resource  = "*"
      }
    ]
  })
}

# IAM Policy for Systems Manager
resource "aws_iam_policy" "prometheus_policy" {
  name        = "prometheus_policy"
  description = "Policy for Systems Manager access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "ssm:*",
        Resource  = "*"
      }
    ]
  })
}


output "policy_grafana_arn" {
  value = aws_iam_policy.grafana_policy.arn
}

output "policy_prometheus_arn" {
  value = aws_iam_policy.prometheus_policy.arn
}