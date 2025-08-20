variable "grafana_policy_arn" {
  description = "Arn of the policy grafana_policy"
}

variable "prometheus_policy_arn" {
  description = "Arn of the prometheus_policy"
}

variable "s3_prometheus_config_policy_arn" {
  type = string
}