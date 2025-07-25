resource "aws_key_pair" "training" {
  key_name   = "awstraining"
  public_key = file("C:\\Users\\jeanl\\.ssh\\id_rsa.pub")
}