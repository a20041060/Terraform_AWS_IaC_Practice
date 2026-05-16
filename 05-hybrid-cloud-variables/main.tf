terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 💡 Architecture Decoupling: Backend parameters are removed 
  # to be injected at runtime using configuration variable files.
  backend "s3" {}
}

# Variable flag used to switch backend networks dynamically
variable "is_localstack" {
  type        = bool
  default     = true
  description = "Set to true for LocalStack simulation, false for a Real AWS Account"
}

provider "aws" {
  region     = "us-east-1"
  
  # Conditional authentication routing
  access_key = var.is_localstack ? "mock_access_key" : null
  secret_key = var.is_localstack ? "mock_secret_key" : null

  skip_credentials_validation = var.is_localstack
  skip_metadata_api_check     = var.is_localstack
  skip_requesting_account_id  = var.is_localstack
  s3_use_path_style           = var.is_localstack

  # 💡 DYNAMIC ENDPOINTS SHIELD
  # If is_localstack is true, it overrides targets to 4566. If false, it drops completely to hit Real AWS endpoints.
  dynamic "endpoints" {
    for_each = var.is_localstack ? [1] : []
    content {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
      iam      = "http://localhost:4566"
      sts      = "http://localhost:4566"
      ec2      = "http://localhost:4566"
    }
  }
}

# ==============================================================================
# BUSINESS ARCHITECTURE (Universal Across All Mock/Real Clouds)
# ==============================================================================
resource "aws_dynamodb_table" "local_db" {
  name         = "${terraform.workspace}-my-local-user-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"
  attribute    { name = "UserID"; type = "S" }
}

resource "aws_s3_bucket" "web_bucket" {
  bucket        = "${terraform.workspace}-my-static-web-bucket-2026"
  force_destroy = true 
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.web_bucket.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/../index.html"
  content_type = "text/html; charset=utf-8"                 
}

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

variable "instance_count" { type = number; default = 2 }

resource "aws_instance" "app_servers" {
  count         = var.instance_count
  ami           = "ami-0c5511574e22ec15b"
  instance_type = "t3.micro"
  subnet_id     = terraform.workspace == "prod" ? module.prod_network.subnet_id : module.dev_network.subnet_id

  user_data = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from ${terraform.workspace} Server ${count.index + 1}</h1>" > index.html
              python3 -m http.server 80 &
              EOF

  tags = { Name = "${terraform.workspace}-web-server-${count.index + 1}" }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute    { name = "LockID"; type = "S" }
}

output "current_universe"    { value = terraform.workspace }
output "dynamodb_table_arn"  { value = aws_dynamodb_table.local_db.arn }
output "app_server_priv_ips" { value = aws_instance.app_servers.*.private_ip }
