# main.tf
provider "aws" {
  region = "us-east-1"
}

variable "public_ssh_key" {
  description = "The public SSH key to use"
  type        = string
}

variable "private_ssh_key" {
  description = "The public SSH key to use"
  type        = string
}

module "key_pair" {
  source         = "./modules/key_pair"
  public_ssh_key = var.public_ssh_key
}

module "security_groups" {
  source = "./modules/security_groups"
}

module "roles" {
  source                = "./modules/roles"
  grafana_policy_arn    = module.policies.policy_grafana_arn
  prometheus_policy_arn = module.policies.policy_prometheus_arn
}

module "policies" {
  source = "./modules/policies"
}

module "ec2_instances" {
  source                      = "./modules/ec2"
  public_ssh_key              = var.public_ssh_key
  private_ssh_key             = var.private_ssh_key
  security_id_server          = module.security_groups.security_group_ids["server"]
  security_id_prometheus      = module.security_groups.security_group_ids["prometheus"]
  security_id_grafana         = module.security_groups.security_group_ids["grafana"]
  grafana_instance_profile    = module.roles.grafana_instance_profile
  prometheus_instance_profile = module.roles.prometheus_instance_profile
}


module "lambdas" {
  source = "./modules/lambda/shutdown_ec2"
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = ["us-est-1a", "us-est-1b"]
}

module "route53" {
  source = "./modules/route53"
}

# module "acm" {
#   source          = "./modules/acm"
#   route53_zone_id = var.route53_zone_id
# }

module "prometheus_alb" {
  source              = "./modules/alb"
  name                = "prometheus-alb"
  vpc_id              = "vpc-06ef89843ae777ffa"
  subnets             = ["subnet-0ce71756846452ea9"]
  security_groups     = ["sg-08bc5a66f905cd066", "sg-032a0ad9ae314e4eb"]
  target_instance_ids = ["i-0ac6f6ca558de626d"]
  health_check_path   = "/-/healthy"
  target_port         = 9090
  # cm_certificate_arn  = module.acm.certificate_arn
}

# module "grafana_alb" {
#   source              = "./modules/alb"
#   name                = "prometheus-alb"
#   vpc_id              = "vpc-06ef89843ae777ffa"
#   subnets             = ["subnet-0ce71756846452ea9"]
#   security_groups     = ["sg-08bc5a66f905cd066", "sg-032a0ad9ae314e4eb"]
#   target_instance_ids = ["i-0ac6f6ca558de626d"]
#   target_port         = 3000
# }