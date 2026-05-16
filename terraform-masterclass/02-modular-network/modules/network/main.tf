resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "${var.env_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1) # Automatically calculates 10.x.1.0/24 splits
  tags       = { Name = "${var.env_name}-public-subnet" }
}

output "vpc_id"    { value = aws_vpc.main.id }
output "subnet_id" { value = aws_subnet.public.id }
