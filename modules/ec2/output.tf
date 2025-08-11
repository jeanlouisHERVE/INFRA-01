output "grafana_instance_id" {
  value = aws_instance.grafana.id
}

output "prometheus_instance_id" {
  value = aws_instance.prometheus.id
}