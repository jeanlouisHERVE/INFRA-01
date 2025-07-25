# resource "aws_instance" "ansible" {
#   ami           = "ami-07d9b9ddc6cd8dd30"
#   instance_type = "t2.micro"
#   iam_instance_profile = var.prometheus_instance_profile 
#   key_name      = "awstraining"

#   tags = {
#     Name = "EC2_ansible"
#     Environment = "Sandbox"
#   }

#   vpc_security_group_ids = [var.security_id_server]
  

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt update",
#       "sudo apt install -y vim",
#       "sudo apt install -y prometheus-node-exporter",
#     ]

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("C:\\Users\\jeanl\\.ssh\\id_rsa")
#       host        = aws_instance.ansible.public_ip
#     }
#   } 
# }