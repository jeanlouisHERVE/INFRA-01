# variable "name" {
#   description = "Prometheus - ALB"
#   type        = string
# }

# variable "vpc_id" {
#   description = "VPC ID"
#   type        = string
# }

# variable "subnets" {
#   description = "List of subnet IDs"
#   type        = list(string)
# }

# variable "security_groups" {
#   description = "Security groups for the ALB"
#   type        = list(string)
# }

# variable "target_port" {
#   description = "Port to forward traffic to (e.g., Prometheus 9090)"
#   type        = number
#   default     = 9090
# }

# variable "health_check_path" {
#   description = "Path to check target health"
#   type        = string
#   default     = "/metrics"
# }

# variable "target_instance_ids" {
#   description = "List of EC2 instance IDs to register"
#   type        = list(string)
#   default     = []
# }

# variable "vpc_cidr_block" {
#   description = "CIDR block of the VPC (e.g., 10.0.0.0/16)"
#   type        = string
# }