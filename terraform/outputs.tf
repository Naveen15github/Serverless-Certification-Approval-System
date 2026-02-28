output "api_gateway_endpoint" {
  description = "The endpoint URL for the API Gateway"
  value       = aws_apigatewayv2_api.cert_approval_api.api_endpoint
}

output "step_functions_state_machine_arn" {
  description = "The ARN of the Step Functions State Machine"
  value       = aws_sfn_state_machine.approval_workflow.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.certification_requests.name
}
