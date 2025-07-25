# main.tf
provider "aws" {
  region = "us-east-1"
}

module "key_pair" {
  source = "./modules/key_pair"
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
  security_id_server          = module.security_groups.security_group_ids["server"]
  security_id_prometheus      = module.security_groups.security_group_ids["prometheus"]
  security_id_grafana         = module.security_groups.security_group_ids["grafana"]
  grafana_instance_profile    = module.roles.grafana_instance_profile
  prometheus_instance_profile = module.roles.prometheus_instance_profile
}

output "grafana_policy_arn" {
  value = module.policies.policy_grafana_arn
}

output "grafana_instance_profile" {
  value = module.roles.grafana_instance_profile
}
