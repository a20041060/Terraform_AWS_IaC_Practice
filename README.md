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

Ensure your LocalStack container is running, execute the manual lock creation command via CLI first to break the paradox loop, and initialize:

```
# 1. Create the lock table in LocalStack
AWS_ACCESS_KEY_ID=mock_key AWS_SECRET_ACCESS_KEY=mock_secret aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url=http://localhost:4566 \
  --region=us-east-1

# 2. Run the secure state synchronization migration tool
terraform init -migrate-state
```

**Verification:** Run `terraform apply`. While it waits for approval, open a separate terminal pane and try running `terraform apply` again. 

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

## 🗂️ Lesson 6: GitOps Automation with GitHub Actions CI/CD Pipelines

**Target Skill:** Production-grade deployment automation. Engineering an active event tracking engine to safely validate configurations locally via branch testing and apply live modifications upon repository merges.

### 🔒 Pre-Flight Credential Safe (GitHub Configuration)

Go to your GitHub repository → **Settings → Secrets and variables → Actions**, and add two Repository Secrets:

- **AWS_ACCESS_KEY_ID:** Your live programmatic production access key
- **AWS_SECRET_ACCESS_KEY:** Your live programmatic production secret key

These credentials will be automatically injected into the GitHub Actions runner environment during pipeline execution, enabling secure authentication to your production AWS account.

### 🏁 Final Exam Certification Run

Follow these steps to complete the DevOps transformation course:

#### Step 1: Create Feature Branch
```bash
git checkout -b feature/lesson-6-test
```

#### Step 2: Push Changes & Create Pull Request
Push your branch changes to GitHub and launch a Pull Request against the `main` branch.

#### Step 3: Watch the GitHub Actions Tab
The runner will:
- Capture the PR trigger event
- Deploy LocalStack inside its isolated runner layer
- Invoke the localstack backend configuration
- Execute a complete Terraform plan validation check
- Verify all infrastructure definitions against mock AWS

This validation phase ensures your Terraform syntax is correct and configurations are sound before touching production.

#### Step 4: Merge to Main
Click **Merge** on your Pull Request.

#### Step 5: Production Deployment Triggered
The pipeline re-evaluates the merge push context and:
- Automatically deactivates the mock LocalStack layers
- Maps to your live AWS account configurations using repository secrets
- Triggers real cloud architecture build on production AWS
- Applies infrastructure changes to your live environment

### 🎓 Congratulations!

You have completed the entire DevOps transformation course! Your infrastructure-as-code pipeline now seamlessly:
- ✅ Validates changes locally on feature branches
- ✅ Tests configurations against mock AWS
- ✅ Enforces code review gates via pull requests
- ✅ Automatically deploys to production on merge
- ✅ Maintains consistent state across environments

### 🐛 Troubleshooting

If any final logs or configuration mappings flag unexpected syntax anomalies as you execute these workflows on your system repository, please share the details with me to patch things up immediately!
