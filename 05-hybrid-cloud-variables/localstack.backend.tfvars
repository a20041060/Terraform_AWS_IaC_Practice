bucket         = "prod-my-static-web-bucket-2026"
key            = "global/s3/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-lock-table"
encrypt        = true
use_path_style = true
access_key     = "mock_access_key"
secret_key     = "mock_secret_key"
endpoints      = { s3 = "http://localhost:4566", dynamodb = "http://localhost:4566", iam = "http://localhost:4566", sts = "http://localhost:4566" }
