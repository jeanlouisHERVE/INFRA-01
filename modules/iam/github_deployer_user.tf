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
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

