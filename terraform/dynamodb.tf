resource "aws_dynamodb_table" "certification_requests" {
  name         = "${var.project_name}-requests-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"

  attribute {
    name = "requestId"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-requests-${var.environment}"
  }
}
