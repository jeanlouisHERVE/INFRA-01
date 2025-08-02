
resource "aws_vpc" "custom" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "custom-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.custom.id
  cidr_block        = cidrsubnet(aws_vpc.custom.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "custom-public-subnet-${count.index}"
  }
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}