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
└── 📁 04-secure-remote-backend/
    ├── main.tf
    └── 📁 modules/
        └── 📁 network/                     (Copied from lab 02)
            ├── main.tf
            └── variables.tf
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

## 🗂️ Folder 4: Secure Remote Backend & State Locking

**Target Skill:** Production Grade CI/CD Safety. Migrating infrastructure state off your local hard drive into cloud buckets while engineering database mutex locks (DynamoDB) to permanently eliminate team race conditions.

**Execution:** Run `cd ../04-secure-remote-backend && terraform init -migrate-state`. Type yes when prompted to upload your system state file into the background mock S3 engine.

**Verification:** Run `terraform apply`. While it waits for approval, open a separate terminal pane and try running `terraform apply` again. You will see a beautiful `Error: Error acquiring the state lock!` database prevention shield.

## 🛑 Post-Lab Deconstruction & Cleanup

Once you finish your DevOps training routine, clear all instances and shutdown your hardware space to return memory and CPU allocations back to your macOS host kernel:

```bash
# Wipe out the localstack engine container along with temporary instances
docker rm -f my-local-aws

# Terminate the background linux hypervisor core
colima stop
```
