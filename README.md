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

