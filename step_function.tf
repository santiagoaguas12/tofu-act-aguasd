resource "aws_sfn_state_machine" "transaction_processor" {
  name     = "${var.project_name}-state-machine"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Serverless banking transaction processor with validation, risk assessment, routing, and one Choice state."
    StartAt = "ValidateTransaction"
    States = {
      ValidateTransaction = {
        Type     = "Task"
        Resource = module.validate_transaction.lambda_arn
        Next     = "AssessRisk"
      }

      AssessRisk = {
        Type     = "Task"
        Resource = module.risk_assess.lambda_arn
        Next     = "RouteTransaction"
      }

      RouteTransaction = {
        Type     = "Task"
        Resource = module.route_transaction.lambda_arn
        Next     = "RiskChoice"
      }

      RiskChoice = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.risk_level"
            StringEquals = "low"
            Next         = "Approved"
          },
          {
            Variable     = "$.risk_level"
            StringEquals = "high"
            Next         = "ManualReview"
          }
        ]
        Default = "InvalidTransaction"
      }

      Approved = {
        Type = "Succeed"
      }

      ManualReview = {
        Type = "Succeed"
      }

      InvalidTransaction = {
        Type  = "Fail"
        Error = "InvalidTransaction"
        Cause = "The transaction failed validation and was stored under the invalid S3 prefix."
      }
    }
  })
}
