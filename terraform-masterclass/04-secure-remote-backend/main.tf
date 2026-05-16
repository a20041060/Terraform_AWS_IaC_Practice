# ==============================================================================
# 1. BASE CONFIGURATION & REMOTE BACKEND STATE LOCKING
# ==============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 💡 Enterprise DevOps Climax: Moving state files to the virtual cloud.
  # This uses the stable assets created during the Lab 03 production universe.
  backend "s3" {
    bucket         = "prod-my-static-web-bucket-2026" # Reuses the Prod environment bucket from Lab 03
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "prod-my-local-user-db"         # Reuses the Prod database table as a mutex lock
    encrypt        = true

    # 💡 Crucial: Hijack backend channels to target local LocalStack instead of real AWS
    endpoint                    = "http://localhost:4566"
    iam_endpoint                = "http://localhost:4566"
    sts_endpoint                = "http://localhost:4566"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    s3_use_path_style           = true
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
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

# ==============================================================================
# 2. DYNAMODB NOSQL DATABASE RESOURCE (Dynamic Workspace Binding)
# ==============================================================================
resource "aws_dynamodb_table" "local_db" {
  name         = "${terraform.workspace}-my-local-user-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }

  tags = {
    Environment = terraform.workspace
  }
}

# ==============================================================================
# 3. STATIC WEB HOSTING & FILE UPLOADS (Dynamic Workspace Namespacing)
# ==============================================================================
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
  source       = "${path.module}/../index.html" # Traverses up to grab the shared asset file
  content_type = "text/html; charset=utf-8"                 
}

# ==============================================================================
# 4. MODULAR NETWORK LAYER (Encapsulating Infrastructure Components)
# ==============================================================================
module "dev_network" {
  source   = "./modules/network" # 💡 Ensure you copy the modules directory here
  vpc_cidr = "10.0.0.0/16"
  env_name = "dev"
}

module "prod_network" {
  source   = "./modules/network"
  vpc_cidr = "172.16.0.0/16"
  env_name = "prod"
}

# ==============================================================================
# 5. COMPUTE INSTANCES CLUSTER (Dynamic Workspace Branching)
# ==============================================================================
variable "instance_count" {
  type    = number
  default = 2
}

resource "aws_instance" "app_servers" {
  count         = var.instance_count
  ami           = "ami-0c5511574e22ec15b"
  instance_type = "t3.micro"
  
  # 💡 Conditional: Assign to prod subnet if in prod workspace, else fallback to dev
  subnet_id     = terraform.workspace == "prod" ? module.prod_network.subnet_id : module.dev_network.subnet_id

  user_data = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from ${terraform.workspace} Server ${count.index + 1}</h1>" > index.html
              python3 -m http.server 80 &
              EOF

  tags = {
    Name = "${terraform.workspace}-web-server-${count.index + 1}"
  }
}

# ==============================================================================
# 6. ARCHITECT ADAPTING OUTPUTS
# ==============================================================================
output "current_universe" {
  value       = terraform.workspace
  description = "The active workspace sandbox environment"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.local_db.arn
  description = "Unique identifier code for the database"
}

output "website_url" {
  value       = "http://${aws_s3_bucket.web_bucket.bucket}.s3-website.localhost.localstack.cloud:4566"
  description = "S3 website hosting URL for the active environment"
}

output "app_server_priv_ips" {
  value       = aws_instance.app_servers.*.private_ip
  description = "List of private IP allocations for the provisioned servers"
}
