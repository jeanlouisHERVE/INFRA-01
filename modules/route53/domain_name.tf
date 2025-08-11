data "aws_route53_zone" "main" {
  name = "secoureo.com"
}

resource "aws_route53_record" "prometheus_dns" {
  zone_id = var.zone_id
  name    = "prometheus.secoureo.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}