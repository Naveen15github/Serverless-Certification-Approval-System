# ==========================================
# HTTP API Gateway
# ==========================================
resource "aws_apigatewayv2_api" "cert_approval_api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.cert_approval_api.id
  name        = "$default"
  auto_deploy = true
}

# ==========================================
# Integrations
# ==========================================

# 1. Submit Request Integration
resource "aws_apigatewayv2_integration" "submit_request" {
  api_id           = aws_apigatewayv2_api.cert_approval_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.submit_request.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "submit_request" {
  api_id    = aws_apigatewayv2_api.cert_approval_api.id
  route_key = "POST /request"
  target    = "integrations/${aws_apigatewayv2_integration.submit_request.id}"
}

resource "aws_lambda_permission" "api_gw_submit_request" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit_request.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cert_approval_api.execution_arn}/*/*"
}

# 2. Handle Approval Integration
resource "aws_apigatewayv2_integration" "handle_approval" {
  api_id           = aws_apigatewayv2_api.cert_approval_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.handle_approval.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "handle_approval" {
  api_id    = aws_apigatewayv2_api.cert_approval_api.id
  route_key = "POST /approval"
  target    = "integrations/${aws_apigatewayv2_integration.handle_approval.id}"
}

resource "aws_lambda_permission" "api_gw_handle_approval" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handle_approval.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cert_approval_api.execution_arn}/*/*"
}


# 3. Check Status Integration
resource "aws_apigatewayv2_integration" "check_status" {
  api_id           = aws_apigatewayv2_api.cert_approval_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.check_status.invoke_arn

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "check_status" {
  api_id    = aws_apigatewayv2_api.cert_approval_api.id
  route_key = "GET /request/{requestId}"
  target    = "integrations/${aws_apigatewayv2_integration.check_status.id}"
}

resource "aws_lambda_permission" "api_gw_check_status" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cert_approval_api.execution_arn}/*/*"
}
