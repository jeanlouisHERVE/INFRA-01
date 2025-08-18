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
  source                          = "./modules/roles"
  grafana_policy_arn              = module.policies.policy_grafana_arn
  prometheus_policy_arn           = module.policies.policy_prometheus_arn
  s3_prometheus_config_policy_arn = module.s3.s3_prometheus_config_policy_arn
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
  subnet_id                   = module.vpc.public_subnet_ids[0]
}

module "lambdas" {
  source = "./modules/lambda/shutdown_ec2"
}

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source = "./modules/s3"
}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

data "aws_route53_zone" "main" {
  name         = "secoureo.com"
  private_zone = false
}

module "route53" {
  source  = "./modules/route53"
  zone_id = data.aws_route53_zone.main.zone_id
  # Prometheus
  prometheus_alb_zone_id  = module.prometheus_alb.prometheus_alb_zone_id
  prometheus_alb_dns_name = module.prometheus_alb.prometheus_alb_dns_name

  # Grafana
  grafana_alb_zone_id  = module.grafana_alb.grafana_alb_zone_id
  grafana_alb_dns_name = module.grafana_alb.grafana_alb_dns_name

}


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

data "aws_instances" "grafana" {
  filter {
    name   = "tag:Name"
    values = ["EC2_grafana"]
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

module "prometheus_alb" {
  source  = "./modules/alb"
  name    = "prometheus-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids
  security_groups = [
    module.security_groups.security_group_ids["prometheus"],
    module.security_groups.security_group_ids["server"]
  ]
  target_instance_ids = [module.ec2_instances.prometheus_instance_id]
  health_check_path   = "/-/healthy"
  target_port         = 9090
}

module "grafana_alb" {
  source  = "./modules/alb"
  name    = "grafana-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids
  security_groups = [
    module.security_groups.security_group_ids["grafana"],
    module.security_groups.security_group_ids["server"]
  ]
  target_instance_ids = [module.ec2_instances.grafana_instance_id]
  health_check_path   = "/-/healthy"
  target_port         = 3000
}