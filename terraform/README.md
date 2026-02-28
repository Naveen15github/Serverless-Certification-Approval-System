# Terraform Deployment Guide

This directory contains the Infrastructure as Code (IaC) configuration to deploy the Serverless Certification Approval System automatically.

The stack provisions:

- An Amazon ECR Repository for Docker images
- An API Gateway (HTTP)
- 4 Containerized AWS Lambda functions
- 1 DynamoDB table
- 1 AWS Step Functions State Machine
- Required IAM Roles and Policies

## Prerequisites

1. **AWS CLI** installed and configured with a profile. This project expects a profile named `<your aws profile>` (you can change this in `providers.tf`).
2. **Terraform** installed (v1.0.0+).
3. **Docker** installed securely and running (required for containerizing the Lambda functions).
4. An Amazon S3 bucket named `<your s3 bucket name>` in `<your region>` for storing the Terraform remote state (you can change this backend configuration in `providers.tf`).

---

## Docker Containerization Reference

The Lambda functions are deployed as a single Docker container image. Here is the `Dockerfile` used:

```dockerfile
# Stage 1: Build dependencies
FROM public.ecr.aws/lambda/python:3.11 AS builder

# Install dependencies into a temporary directory
COPY requirements.txt .
RUN pip install -r requirements.txt --target /var/task/

# Stage 2: Final image
FROM public.ecr.aws/lambda/python:3.11

# Copy dependencies from builder stage
COPY --from=builder /var/task/ /var/task/

# Copy all function code
COPY submit_request.py /var/task/
COPY notify_manager.py /var/task/
COPY handle_approval.py /var/task/
COPY check_status.py /var/task/

# Default command (will be overridden by Terraform for each specific Lambda function)
CMD ["submit_request.lambda_handler"]
```

---

## Deployment Steps (Ordered Sequence)

### Step 1: Initialize Terraform

Navigate to the `terraform` directory in your terminal and run:

```bash
terraform init
```

This downloads necessary providers and sets up the remote backend.

### Step 2: Provision ECR Repository First

Because our Lambda functions rely on a Docker image loaded into ECR, we must create the ECR repository _before_ we attempt to build the Docker image or deploy the Lambdas.

```bash
terraform apply -target=aws_ecr_repository.lambda_repo
```

Type `yes` when prompted.

### Step 3: Build and Push the Docker Image

Navigate strictly back to the root project directory and execute the bash script to package the 4 lambda functions into a single Docker image and push it to AWS ECR:

```bash
cd ..
./build_and_push.sh
```

_Note: Ensure Docker is running. The script uses the `<your aws profile>` AWS profile. Under the hood, this script runs `docker build --platform linux/amd64 --provenance=false -t ...` and then pushes the tags to ECR._

### Step 4: Deploy the Architecture

Navigate back to the `terraform` folder and apply the rest of the infrastructure. Terraform will configure API Gateway, DynamoDB, Step Functions, and the containerized Lambda functions.

```bash
cd terraform
terraform apply
```

Type `yes` to confirm.

Wait for the deployment to finish. Terraform will output three variables at the end:

- `api_gateway_endpoint`
- `dynamodb_table_name`
- `step_functions_state_machine_arn`

---

## How to Test and Verify

Once `terraform apply` is complete, you can test the backend via the command line. Take the `api_gateway_endpoint` output (e.g., `https://xyz.execute-api...com`) and run:

**1. Create a Request**

```bash
curl -X POST <api_gateway_endpoint>/request \
  -H "Content-Type: application/json" \
  -d '{"name":"Eric Terraform","course":"AWS Mastery","cost":300}'
```

This will return a `requestId`.

**2. Check the logs for the Task Token**

```bash
# Wait ~5 seconds, then grab the token printed by the NotifyManager Lambda
aws logs filter-log-events \
  --log-group-name /aws/lambda/cert-approval-NotifyManager-dev \
  --region <your region> \
  --profile <your aws profile> \
  --filter-pattern '"<YOUR_REQUEST_ID_HERE>"'
```

Find the `APPROVAL TOKEN: <huge string>` in out outputs and copy the token.

**3. Approve the Request**

```bash
curl -X POST <api_gateway_endpoint>/approval \
  -H "Content-Type: application/json" \
  -d '{
    "requestId":"<YOUR_REQUEST_ID_HERE>",
    "decision":"APPROVED",
    "taskToken":"<YOUR_TOKEN_HERE>"
  }'
```

**4. Check the Request Status**

```bash
curl <api_gateway_endpoint>/status/<YOUR_REQUEST_ID_HERE>
```

If everything worked correctly, the API will tell you the status is `APPROVED`.

## Teardown

To destroy all provisioned resources cleanly:

```bash
terraform destroy
```
