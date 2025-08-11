variable "zone_id" {
  description = "The Route 53 hosted zone ID for secoureo.com"
  type        = string
}

variable "prometheus_alb_dns_name" {
  description = "DNS name of the ALB prometheus"
  type = string
}

variable "prometheus_alb_zone_id" {
  description = "Zone ID of the ALB prometheus"
  type = string
}

variable "grafana_alb_dns_name" {
  description = "DNS name of the ALB grafana"
  type = string
}

variable "grafana_alb_zone_id" {
  description = "Zone ID of the ALB grafana"
  type = string
}