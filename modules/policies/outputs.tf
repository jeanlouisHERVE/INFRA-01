output "policy_grafana_arn" {
  value = aws_iam_policy.grafana_policy.arn
}

output "policy_prometheus_arn" {
  value = aws_iam_policy.prometheus_policy.arn
}