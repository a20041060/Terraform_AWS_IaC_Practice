terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  endpoints {
    ec2 = "http://localhost:4566" # Added to prevent 401 AWS errors during module creation
  }
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

output "dev_vpc_id"  { value = module.dev_network.vpc_id }
output "prod_vpc_id" { value = module.prod_network.vpc_id }
