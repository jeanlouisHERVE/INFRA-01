resource "aws_instance" "grafana" {
  ami                  = "ami-07d9b9ddc6cd8dd30"
  instance_type        = "t2.micro"
  iam_instance_profile = var.grafana_instance_profile 
  key_name             = var.key_name
  subnet_id            = var.subnet_id

  tags = {
    Name = "EC2_grafana"
    Environment = "DEV"
  }

  vpc_security_group_ids = [var.security_id_grafana, var.security_id_server, var.security_id_node-exporter]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y vim",
    ]

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file(var.private_key_path)
        host        = self.public_ip
    }
  } 
}
