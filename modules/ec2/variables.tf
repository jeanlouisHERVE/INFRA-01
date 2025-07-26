
variable "security_id_server" {
  description = "Security Group ID for Server instances"
}

variable "security_id_prometheus" {
  description = "Security Group ID for Prometheus instances"
}

variable "security_id_grafana" {
  description = "Security Group ID for Grafana instances"
}

variable "grafana_instance_profile" {
  description = "Instance profile ARN or name for Grafana EC2"
  type        = string
}

variable "prometheus_instance_profile" {
  description = "Instance profile ARN or name for Prometheus EC2"
  type        = string
}

variable "public_ssh_key" {
  description = "Private SSH key content for connection"
  type        = string
  sensitive   = true
}

variable "private_ssh_key" {
  description = "Private SSH key content for connection"
  type        = string
  sensitive   = true
}