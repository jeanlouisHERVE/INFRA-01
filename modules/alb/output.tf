output "prometheus_alb_zone_id" {
  value = aws_lb.prometheus_alb.zone_id
}

output "prometheus_alb_dns_name" {
  value = aws_lb.prometheus_alb.dns_name
}