# main.tf
provider "aws" {
  region = "us-east-1"
}

module "key_pair" {
  source          = "./modules/key_pair"
  key_name        = var.key_name
  public_key_path = var.public_key_path
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
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
  key_name                    = module.key_pair.key_name
  public_key_path             = var.public_key_path
  private_key_path            = var.private_key_path
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
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "route53" {
  source = "./modules/route53"
}

# module "acm" {
#   source          = "./modules/acm"
#   route53_zone_id = var.route53_zone_id
# }

data "aws_instances" "prometheus" {
  filter {
    name   = "tag:Name"
    values = ["EC2_prometheus"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }
}

data "aws_security_groups" "all_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
}

output "all_sg_ids" {
  value = data.aws_security_groups.all_in_vpc.ids
}

module "prometheus_alb" {
  count   = length(data.aws_instances.prometheus.ids) > 0 ? 1 : 0
  source  = "./modules/alb"
  name    = "prometheus-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids
  security_groups = [
    module.security_groups.security_group_ids["prometheus"],
    module.security_groups.security_group_ids["server"]
  ]
  target_instance_ids = [data.aws_instances.prometheus.ids[0]]
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