
resource "aws_instance" "grafana" {
  ami                    = "ami-07d9b9ddc6cd8dd30"
  instance_type          = "t2.micro"
  iam_instance_profile   = var.grafana_instance_profile


  vpc_security_group_ids = [var.security_id_grafana, var.security_id_server]

  tags = {
    Name        = "EC2_grafana"
    Environment = "Sandbox"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y vim",
      "sudo apt install -y prometheus-node-exporter",
    ]

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = var.private_ssh_key
        host        = self.public_ip
    }
  }
}