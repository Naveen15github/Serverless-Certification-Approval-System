resource "aws_ecr_repository" "lambda_repo" {
  name                 = "cert-approval-lambda-repo-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allow destroying the repo even if it contains images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecr_lifecycle_policy" "lambda_repo_policy" {
  repository = aws_ecr_repository.lambda_repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 5 images",
      selection = {
        tagStatus   = "any",
        countType   = "imageCountMoreThan",
        countNumber = 5
      },
      action = {
        type = "expire"
      }
    }]
  })
}
