resource "aws_key_pair" "training" {
  key_name   = "training"
  public_key = var.PUBLIC_SSH_KEY
}