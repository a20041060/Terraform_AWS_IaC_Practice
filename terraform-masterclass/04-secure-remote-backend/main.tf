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

  # 💡 Enterprise DevOps Climax: Relocating state tracking into virtual cloud storage.
  # This targets the dynamic multi-tenant infrastructure inside LocalStack.
  backend "s3" {
    bucket         = "prod-my-static-web-bucket-2026" # Reuses the Prod environment bucket from Lab 03
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    
    # 💡 Core Constraint: Targets the dedicated state locking table initialized via CLI
    dynamodb_table = "terraform-lock-table" 
    
    encrypt        = true
    use_path_style = true # Overrides domain routing constraints on local Mac setups

    # 💡 Security Fix: Explicitly provides mock credentials to the core backend engine
    access_key     = "mock_access_key"
    secret_key     = "mock_secret_key"

    # 💡 Upgraded Syntax: Modern structured map block to bypass deprecation warnings
    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
      iam      = "http://localhost:4566"
      sts      = "http://localhost:4566"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  use_path_style           = true 

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
    ec2      = "http://localhost:4566"
  }
}

# ==============================================================================
# 2. BUSINESS DYNAMODB DATABASE (Dynamic Workspace Multi-Tenant Universe)
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
# 3. STATIC WEB HOSTING & CONTENT OBJECT UPLOADS
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
  source       = "${path.module}/../index.html" # Traverses to the root directory asset
  content_type = "text/html; charset=utf-8"                 
}

# ==============================================================================
# 4. ENCAPSULATED REUSABLE NETWORKING MODULES
# ==============================================================================
module "dev_network" {
  source   = "./modules/network" # 💡 Remember to copy your modules folder into this directory
  vpc_cidr = "10.0.0.0/16"
  env_name = "dev"
}

module "prod_network" {
  source   = "./modules/network"
  vpc_cidr = "172.16.0.0/16"
  env_name = "prod"
}

# ==============================================================================
# 5. ELASTIC WEB SERVERS COMPUTE INSTANCES CLUSTER
# ==============================================================================
variable "instance_count" {
  type    = number
  default = 2
}

resource "aws_instance" "app_servers" {
  count         = var.instance_count
  ami           = "ami-0c5511574e22ec15b"
  instance_type = "t3.micro"
  
  # 💡 Conditional Switch: Assigns to prod network if inside prod space, else fallbacks to dev
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
# 6. STANDALONE TEAM STATE LOCK TABLE
# ==============================================================================
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" # 💡 Mandatory name format requirement for locking mechanisms

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

# ==============================================================================
# 7. LOG OUTPUTS
# ==============================================================================
output "current_universe" {
  value       = terraform.workspace
  description = "The active workspace sandbox environment space"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.local_db.arn
  description = "Unique identifier ARN for the current business data space"
}

output "website_url" {
  value       = "http://${aws_s3_bucket.web_bucket.bucket}.s3-website.localhost.localstack.cloud:4566"
  description = "S3 website hosting URL for checking your deployed page"
}

output "app_server_priv_ips" {
  value       = aws_instance.app_servers.*.private_ip
  description = "Private IP addresses map for the compute instances running in this zone"
}
