output "bucket_name" {
  description = "S3 bucket where transaction processing results are stored."
  value       = aws_s3_bucket.results.bucket
}

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine."
  value       = aws_sfn_state_machine.transaction_processor.arn
}

output "validate_lambda_name" {
  description = "Name of the ValidateTransaction Lambda function."
  value       = module.validate_transaction.lambda_name
}

output "risk_lambda_name" {
  description = "Name of the RiskAssess Lambda function."
  value       = module.risk_assess.lambda_name
}

output "route_lambda_name" {
  description = "Name of the RouteTransaction Lambda function."
  value       = module.route_transaction.lambda_name
}
