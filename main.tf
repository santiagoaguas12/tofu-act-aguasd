resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  lambda_runtime = "python3.12"
}

resource "aws_s3_bucket" "results" {
  bucket        = "${var.project_name}-results-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

module "validate_transaction" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-validate-transaction"
  source_dir    = "${path.root}/lambdas/validate_transaction"
  role_arn      = aws_iam_role.lambda_basic_role.arn
  runtime       = local.lambda_runtime
}

module "risk_assess" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-risk-assess"
  source_dir    = "${path.root}/lambdas/risk_assess"
  role_arn      = aws_iam_role.lambda_basic_role.arn
  runtime       = local.lambda_runtime
}

module "route_transaction" {
  source = "./modules/lambda_function"

  function_name = "${var.project_name}-route-transaction"
  source_dir    = "${path.root}/lambdas/route_transaction"
  role_arn      = aws_iam_role.lambda_route_role.arn
  runtime       = local.lambda_runtime

  environment_variables = {
    BUCKET_NAME = aws_s3_bucket.results.bucket
  }
}
