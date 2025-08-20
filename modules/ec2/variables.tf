
variable "security_id_server" {
  description = "Security Group ID for Server instances"
}

variable "security_id_prometheus" {
  description = "Security Group ID for Prometheus instances"
}

variable "security_id_grafana" {
  description = "Security Group ID for Grafana instances"
}

variable "security_id_node-exporter" {
  description = "Security Group ID to use node-exporter"
}

variable "grafana_instance_profile" {
  description = "Instance profile ARN or name for Grafana EC2"
  type        = string
}

variable "prometheus_instance_profile" {
  description = "Instance profile ARN or name for Prometheus EC2"
  type        = string
}

variable "public_key_path" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "key_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be deployed"
  type        = string
}