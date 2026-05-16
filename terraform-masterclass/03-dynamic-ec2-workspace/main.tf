terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
    ec2      = "http://localhost:4566"
  }
}

# Network Modules
module "dev_network" {
  source   = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
  env_name = "dev"
}

module "prod_network" {
  source   = "./modules/network"
  vpc_cidr = "172.16.0.0/16"
  env_name = "prod"
}

# Dynamic Workspace Resources
resource "aws_dynamodb_table" "local_db" {
  name           = "${terraform.workspace}-my-local-user-db"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }
}

resource "aws_s3_bucket" "web_bucket" {
  bucket        = "${terraform.workspace}-my-static-web-bucket-2026"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html; charset=utf-8"
}

# DevOps Automation: Compute Clusters
variable "instance_count" {
  type    = number
  default = 2
}

resource "aws_instance" "app_servers" {
  count         = var.instance_count
  ami           = "ami-0c5511574e22ec15b"
  instance_type = "t3.micro"

  # Dynamic branching based on active workspace universe
  subnet_id = terraform.workspace == "prod" ? module.prod_network.subnet_id : module.dev_network.subnet_id

  user_data = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from ${terraform.workspace} Server ${count.index + 1}</h1>" > index.html
              python3 -m http.server 80 &
              EOF

  tags = {
    Name = "${terraform.workspace}-web-server-${count.index + 1}"
  }
}

# Workspace Adapting Outputs
output "current_universe" {
  value = terraform.workspace
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.local_db.arn
}

output "app_server_priv_ips" {
  value = aws_instance.app_servers.*.private_ip
}
