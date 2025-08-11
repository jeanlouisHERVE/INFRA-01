data "aws_route53_zone" "main" {
  name = "secoureo.com"
}

resource "aws_route53_record" "prometheus_dns" {
  zone_id = var.zone_id
  name    = "prometheus.secoureo.com"
  type    = "A"

  alias {
    name                   = var.prometheus_alb_dns_name
    zone_id                = var.prometheus_alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana_dns" {
  zone_id = var.zone_id
  name    = "grafana.secoureo.com"
  type    = "A"

  alias {
    name                   = var.grafana_alb_dns_name
    zone_id                = var.grafana_alb_zone_id
    evaluate_target_health = false
  }
}