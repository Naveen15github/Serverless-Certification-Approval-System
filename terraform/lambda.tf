# ==========================================
# Lambda Functions (Containerized)
# ==========================================

locals {
  ecr_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/cert-approval-lambda-repo-${var.environment}:latest"
}

# 1. Submit Request
resource "aws_lambda_function" "submit_request" {
  function_name = "${var.project_name}-SubmitRequest-${var.environment}"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = local.ecr_image_uri

  image_config {
    command = ["submit_request.lambda_handler"]
  }

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.approval_workflow.arn
    }
  }

  depends_on = [aws_ecr_repository.lambda_repo]
}

# 2. Notify Manager
resource "aws_lambda_function" "notify_manager" {
  function_name = "${var.project_name}-NotifyManager-${var.environment}"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = local.ecr_image_uri

  image_config {
    command = ["notify_manager.lambda_handler"]
  }

  depends_on = [aws_ecr_repository.lambda_repo]
}

# 3. Handle Approval
resource "aws_lambda_function" "handle_approval" {
  function_name = "${var.project_name}-HandleApproval-${var.environment}"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = local.ecr_image_uri

  image_config {
    command = ["handle_approval.lambda_handler"]
  }

  depends_on = [aws_ecr_repository.lambda_repo]
}

# 4. Check Status
resource "aws_lambda_function" "check_status" {
  function_name = "${var.project_name}-CheckStatus-${var.environment}"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = local.ecr_image_uri

  image_config {
    command = ["check_status.lambda_handler"]
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.certification_requests.name
    }
  }

  depends_on = [aws_ecr_repository.lambda_repo]
}
