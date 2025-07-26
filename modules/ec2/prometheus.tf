resource "aws_instance" "prometheus" {
  ami                  = "ami-07d9b9ddc6cd8dd30"
  instance_type        = "t2.micro"
  iam_instance_profile = var.prometheus_instance_profile 
  key_name             = "awstraining"

  tags = {
    Name = "EC2_prometheus"
    Environment = "Sandbox"
  }

  vpc_security_group_ids = [var.security_id_prometheus, var.security_id_server]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y vim",
    ]

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = var.private_ssh_key
        host        = self.public_ip
    }
  } 
}