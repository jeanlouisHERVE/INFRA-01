output "all_sg_ids" {
  value = data.aws_security_groups.all_in_vpc.ids
}

output "aws_github_user_access_key_id" {
  value     = module.iam.aws_github_user_access_key_id
  sensitive = true
}

output "aws_github_user_secret_access_key" {
  value     = module.iam.aws_github_user_secret_access_key
  sensitive = true
}