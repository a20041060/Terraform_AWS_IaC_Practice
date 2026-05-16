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
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true # Fixes local Mac .localhost routing errors

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
  }
}

resource "aws_dynamodb_table" "local_db" {
  name         = "my-local-user-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }
}

resource "aws_s3_bucket" "web_bucket" {
  bucket        = "my-terraform-static-website-bucket"
  force_destroy = true 
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.web_bucket.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_object" "upload_index" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/../index.html" # References the shared root HTML file
  content_type = "text/html; charset=utf-8"                 
}

output "dynamodb_table_arn" { value = aws_dynamodb_table.local_db.arn }
output "website_url"        { value = "http://${aws_s3_bucket.web_bucket.bucket}.s3-website.localhost.localstack.cloud:4566" }
