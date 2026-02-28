#!/bin/bash
set -e

# Default variables
REGION="<your region>"
PROFILE="<your aws profile>"
REPO_NAME="cert-approval-lambda-repo-dev"

# Get the AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --profile $PROFILE --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo "Failed to get AWS Account ID. Is your '$PROFILE' profile configured correctly?"
    exit 1
fi

ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_URI="${ECR_URI}/${REPO_NAME}"

# Generate a unique tag based on current timestamp
IMAGE_TAG=$(date +%Y%m%d%H%M%S)

echo "=========================================="
echo " Building and Pushing Docker Image to ECR "
echo " Repository: $IMAGE_URI"
echo " Tag: $IMAGE_TAG"
echo "=========================================="

# Authenticate Docker to ECR
echo "[1/4] Authenticating with ECR..."
aws ecr get-login-password --region $REGION --profile $PROFILE | docker login --username AWS --password-stdin $ECR_URI

# Build the Docker image
echo "[2/4] Building Docker image..."
# Use platform linux/amd64 which is the default for AWS Lambda unless arm64 is explicitly configured
# Important: AWS Lambda does not support OCI image manifests with attestations. We MUST use --provenance=false
docker build --platform linux/amd64 --provenance=false -t ${REPO_NAME}:${IMAGE_TAG} .

# Tag the image for ECR (tag with specific version AND latest)
echo "[3/4] Tagging images..."
docker tag ${REPO_NAME}:${IMAGE_TAG} ${IMAGE_URI}:${IMAGE_TAG}
docker tag ${REPO_NAME}:${IMAGE_TAG} ${IMAGE_URI}:latest

# Push the images to ECR
echo "[4/4] Pushing images to ECR..."
docker push ${IMAGE_URI}:${IMAGE_TAG}
docker push ${IMAGE_URI}:latest

echo "=========================================="
echo "✅ Success!"
echo "Image URI: ${IMAGE_URI}:${IMAGE_TAG}"
echo "Configure your Terraform lambda.tf to use:"
echo "${IMAGE_URI}:latest"
echo "=========================================="
