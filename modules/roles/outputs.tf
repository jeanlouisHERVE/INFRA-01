output "grafana_instance_profile" {
  value = aws_iam_instance_profile.grafana_instance_profile.name
}

output "prometheus_instance_profile" {
  value = aws_iam_instance_profile.prometheus_instance_profile.name
}