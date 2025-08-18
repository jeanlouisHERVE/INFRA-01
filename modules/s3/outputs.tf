output "s3_prometheus_config_policy_arn" {
  value = aws_iam_policy.ec2_access_s3_prometheus_policy.arn
}