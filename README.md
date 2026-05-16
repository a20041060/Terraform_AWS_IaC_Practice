terraform-masterclass/
├── index.html                           # Shared English web page asset
├── 01-basic-s3-dynamodb/
│   └── main.tf
├── 02-modular-network/
│   ├── main.tf
│   └── modules/
│       └── network/
│           ├── main.tf
│           └── variables.tf
├── 03-dynamic-ec2-workspace/
│   ├── main.tf
│   └── modules/
│       └── network/                     # (Copied from lab 02)
│           ├── main.tf
│           └── variables.tf
└── 04-secure-remote-backend/
    ├── main.tf
    └── modules/
        └── network/                     # (Copied from lab 02)
            ├── main.tf
            └── variables.tf

🛠️ Lab Global Setup (Prerequisites)
Before running any lab, ensure your lightweight local container brain and "Mock AWS" are running:

# Start your background Docker daemon via Colima
colima start

# Launch the zero-cost LocalStack 3.8.0 Mock AWS API engine
docker run -d --name my-local-aws -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack:3.8.0
