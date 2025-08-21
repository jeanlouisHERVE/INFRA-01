resource "aws_iam_user" "github_deployer" {
  name = "github-actions-deployer"
}

# Access key for the IAM user
resource "aws_iam_access_key" "github_deployer_key" {
  user = aws_iam_user.github_deployer.name
}

# Inline policy for SSM + EC2 read-only
resource "aws_iam_user_policy" "github_deployer_policy" {
  name = "github-deployer-policy"
  user = aws_iam_user.github_deployer.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ec2:DescribeInstances",
          "s3:PutObject"
        ],
        Resource = "*"
      }
    ]
  })
}

# Secret for the access key ID
resource "aws_secretsmanager_secret" "github_access_key_id" {
  name = "SECOUREO/USER/GITHUB_DEPLOYER/KEY_ID"
}

resource "aws_secretsmanager_secret_version" "github_access_key_id" {
  secret_id     = aws_secretsmanager_secret.github_access_key_id.id
  secret_string = aws_iam_access_key.github_deployer_key.id
}

# Secret for the secret access key
resource "aws_secretsmanager_secret" "github_secret_access_key" {
  name = "SECOUREO/USER/GITHUB_DEPLOYER/ACCESS_KEY"
}

resource "aws_secretsmanager_secret_version" "github_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.github_secret_access_key.id
  secret_string = aws_iam_access_key.github_deployer_key.secret
}

