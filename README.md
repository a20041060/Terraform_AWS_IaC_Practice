```
terraform-masterclass/
│
├── 📄 index.html                           (Shared English web page asset)
│
├── 📁 01-basic-s3-dynamodb/
│   └── main.tf
│
├── 📁 02-modular-network/
│   ├── main.tf
│   └── 📁 modules/
│       └── 📁 network/
│           ├── main.tf
│           └── variables.tf
│
├── 📁 03-dynamic-ec2-workspace/
│   ├── main.tf
│   └── 📁 modules/
│       └── 📁 network/                     (Copied from lab 02)
│           ├── main.tf
│           └── variables.tf
│
├── 📁 04-secure-remote-backend/
│   ├── main.tf
│   └── 📁 modules/
│       └── 📁 network/                     (Copied from lab 02)
│           ├── main.tf
│           └── variables.tf
│
├── 📁 05-hybrid-cloud-variables/           # (Lesson 5)
│   ├── main.tf
│   ├── aws.backend.tfvars
│   ├── localstack.backend.tfvars
│   └── 📁 modules/
│       └── 📁 network/                     (Copied from lab 02)
│
└── 📁 06-github-actions-cicd/              # (Lesson 6)
    └── 📁 .github/
        └── 📁 workflows/
            └── terraform-pipeline.yml
```

## 🛠️ Lab Global Setup (Prerequisites)

Before running any lab, ensure your lightweight local container brain and "Mock AWS" are running:

```bash
# Start your background Docker daemon via Colima
colima start

# Launch the zero-cost LocalStack 3.8.0 Mock AWS API engine
docker run -d --name my-local-aws -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack:3.8.0
```

## 🗂️ Folder 1: Basic S3 & DynamoDB Deployment

**Target Skill:** Core syntax, basic state management, endpoint hijacking for mock cloud environments, and fixing S3 URL resolutions (s3_use_path_style).

**Execution:** Run `cd 01-basic-s3-dynamodb && terraform init && terraform apply`.

**Verification:** Run `AWS_ACCESS_KEY_ID=mock AWS_SECRET_ACCESS_KEY=mock aws dynamodb list-tables --endpoint-url=http://localhost:4566`

## 🗂️ Folder 2: Modular Network Architecture

**Target Skill:** Infrastructure encapsulation. Building reusable network blueprints (modules) to instantly map multi-tier environments without writing repetitive blocks.

**Execution:** Run `cd ../02-modular-network && terraform init && terraform apply`.

**Verification:** Run `AWS_ACCESS_KEY_ID=mock AWS_SECRET_ACCESS_KEY=mock aws ec2 describe-vpcs --endpoint-url=http://localhost:4566`

## 🗂️ Folder 3: Dynamic Multi-VM & Workspace Scopes

**Target Skill:** DevOps orchestration. Using count and ternary conditions combined with terraform.workspace to seamlessly alternate resource namespaces and server scale with a single template.

**Execution (Dev Space):** Run `terraform workspace select -or-create dev && terraform apply -auto-approve`

**Execution (Prod Space):** Run `terraform workspace select -or-create prod && terraform apply -auto-approve`

**Infrastructure Architecture (Mock AWS Cloud Environment - LocalStack Region: us-east-1):**

```
Mock AWS Cloud Environment (LocalStack Region: us-east-1)
├── 🗄️ DynamoDB (my-local-user-db) <──────────────┐ (Shared across all 3 machines)
├── 🌐 S3 Bucket (my-terraform-static-website) <────┤ 
│                                                  │
├── [ 🌐 Dev VPC (10.0.0.0/16) ]                   │
│     └── [ Public Subnet (10.0.1.0/24) ]          │
│           ├── 💻 EC2 (dev-web-server-1) ─────────┤
│           ├── 💻 EC2 (dev-web-server-2) ─────────┤
│           └── 💻 EC2 (dev-web-server-3) ─────────┘
│
└── [ 🌐 Prod VPC (172.16.0.0/16) ]
      └── [ Public Subnet (172.16.1.0/24) ]
```

## 🗂️ Folder 4: Secure Remote Backend & State Locking

**Target Skill:** Production Grade CI/CD Safety. Migrating infrastructure state off your local hard drive into cloud buckets while engineering database mutex locks (DynamoDB) to permanently eliminate [...]

**Execution:** Run `cd ../04-secure-remote-backend && terraform init -migrate-state`. Type yes when prompted to upload your system state file into the background mock S3 engine.

**Verification:** Run `terraform apply`. While it waits for approval, open a separate terminal pane and try running `terraform apply` again. You will see a beautiful `Error: Error acquiring the state [...]

## 🛑 Post-Lab Deconstruction & Cleanup

Once you finish your DevOps training routine, clear all instances and shutdown your hardware space to return memory and CPU allocations back to your macOS host kernel:

```bash
# Wipe out the localstack engine container along with temporary instances
docker rm -f my-local-aws

# Terminate the background linux hypervisor core
colima stop
```

## 🗂️ Lesson 5: Hybrid Cloud Architecture & Decoupled Configurations

**Target Skill:** Dual-mode abstraction. Upgrading structural definitions to alternate smoothly between LocalStack and Real AWS Production without altering core resource blocks.

**Execution:** Copy your networking modules folder into this directory, then explicitly inject the backend configuration files during initialization:

```bash
terraform init -backend-config=localstack.backend.tfvars
```

**Hybrid Cloud Flexibility:** This lesson demonstrates how to maintain a single Terraform configuration that seamlessly switches between environments:

- **LocalStack Mode:** Use `terraform init -backend-config=localstack.backend.tfvars` to deploy to mock AWS locally
- **Production AWS Mode:** Use `terraform init -backend-config=aws.backend.tfvars` to deploy to real AWS infrastructure

**Key Concepts:**
- Backend abstraction through external tfvars files
- Provider endpoint configuration for multi-cloud compatibility
- State isolation between environments
- Consistent resource definitions across deployment targets

**Verification (LocalStack):** After applying with localstack backend:
```bash
AWS_ACCESS_KEY_ID=mock AWS_SECRET_ACCESS_KEY=mock aws s3 ls --endpoint-url=http://localhost:4566
```

**Verification (AWS):** After applying with aws backend:
```bash
aws s3 ls
```

This architecture enables your team to develop and test infrastructure locally before confidently deploying to production AWS accounts.
