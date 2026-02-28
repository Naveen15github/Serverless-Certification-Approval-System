resource "aws_sfn_state_machine" "approval_workflow" {
  name     = "${var.project_name}-ApprovalStateMachine-${var.environment}"
  role_arn = aws_iam_role.sfn_exec_role.arn

  definition = jsonencode({
    Comment = "A Serverless Certification Approval Workflow"
    StartAt = "SaveRequestToDynamoDB"
    States = {
      SaveRequestToDynamoDB = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:putItem"
        Parameters = {
          TableName = aws_dynamodb_table.certification_requests.name
          Item = {
            "requestId" = {
              "S.$" = "$.requestId"
            }
            "name" = {
              "S.$" = "$.name"
            }
            "course" = {
              "S.$" = "$.course"
            }
            "cost" = {
              "N.$" = "States.Format('{}', $.cost)"
            }
            "status" = {
              "S" = "PENDING"
            }
            "requestDate" = {
              "S.$" = "$.requestDate"
            }
          }
        }
        ResultPath = null
        Next       = "NotifyManagerAndWait"
      }
      NotifyManagerAndWait = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke.waitForTaskToken"
        Parameters = {
          FunctionName = aws_lambda_function.notify_manager.arn
          Payload = {
            "taskToken.$" = "$$.Task.Token"
            "requestId.$" = "$.requestId"
            "name.$"      = "$.name"
            "course.$"    = "$.course"
            "cost.$"      = "$.cost"
          }
        }
        ResultPath = "$.managerDecision"
        Next       = "UpdateFinalStatusInDynamoDB"
      }
      UpdateFinalStatusInDynamoDB = {
        Type     = "Task"
        Resource = "arn:aws:states:::dynamodb:updateItem"
        Parameters = {
          TableName = aws_dynamodb_table.certification_requests.name
          Key = {
            "requestId" = {
              "S.$" = "$.requestId"
            }
          }
          UpdateExpression = "SET #status = :newStatus, processedAt = :processedAt"
          ExpressionAttributeNames = {
            "#status" = "status"
          }
          ExpressionAttributeValues = {
            ":newStatus" = {
              "S.$" = "$.managerDecision.status"
            }
            ":processedAt" = {
              "S.$" = "$.managerDecision.processedAt"
            }
          }
        }
        End = true
      }
    }
  })
}
