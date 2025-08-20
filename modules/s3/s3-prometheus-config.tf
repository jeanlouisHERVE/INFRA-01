# Création du bucket S3
resource "aws_s3_bucket" "prometheus_configs" {
  bucket = "prometheus-config-secoureo-bucket" 
}

# (Optionnel) Versioning pour pouvoir rollback facilement
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.prometheus_configs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# (Optionnel) Bloquer l'accès public
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.prometheus_configs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "ec2_access_s3_prometheus" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.prometheus_configs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ec2_access_s3_prometheus_policy" {
  name   = "EC2S3AccessPolicy"
  policy = data.aws_iam_policy_document.ec2_access_s3_prometheus.json
}