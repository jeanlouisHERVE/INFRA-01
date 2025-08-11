output "prometheus_alb_zone_id" {
  value = aws_lb.prometheus_alb.zone_id
}

output "prometheus_alb_dns_name" {
  value = aws_lb.prometheus_alb.dns_name
}

output "grafana_alb_zone_id" {
  value = aws_lb.grafana_alb.zone_id
}

output "grafana_alb_dns_name" {
  value = aws_lb.grafana_alb.dns_name
}