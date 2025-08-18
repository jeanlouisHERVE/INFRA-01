
# IAM Role for Grafana
resource "aws_iam_role" "grafana_role" {
  name = "grafana_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::796305661356:user/Jean-Louis"
        },
        Action    = "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# IAM Role for Systems Manager
resource "aws_iam_role" "prometheus_role" {
  name = "prometheus_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Create the IAM instance profile 
resource "aws_iam_instance_profile" "grafana_instance_profile" {
  name = "grafana_instance_profile"
  role = aws_iam_role.grafana_role.name
}

resource "aws_iam_instance_profile" "prometheus_instance_profile" {
  name = "prometheus_instance_profile"
  role = aws_iam_role.prometheus_role.name
}

# Attach the IAM Policy 

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_attachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = var.grafana_policy_arn
}


# Attach SSM policy to your existing roles
resource "aws_iam_role_policy_attachment" "grafana_role_ssm" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "prometheus_role_ssm" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach IAM Policy to the User
resource "aws_iam_user_policy_attachment" "attach_cloudwatch_policy_to_user" {
  user       = "Jean-Louis"
  policy_arn = var.grafana_policy_arn
}

# Attach Attach IAM Policy S3 access for prometheus config files to prometheus server 
resource "aws_iam_role_policy_attachment" "attach_s3_to_grafana_role" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = module.s3.ec2_access_s3_prometheus_policy_arn
}
