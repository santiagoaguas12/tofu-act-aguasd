# Banking Transaction Processor

This project implements a small serverless banking transaction processor for an academic Big Data activity. It is deployed completely with OpenTofu and does not require creating any resource manually in the AWS Console. The pipeline simulates a simple anti-fraud flow: a transaction is validated, assessed for risk, written to Amazon S3, and then finalized by an AWS Step Functions state machine.

## Architecture

The solution creates one S3 bucket, exactly three AWS Lambda functions using Python 3.12, and exactly one Step Functions state machine. The Lambdas are:

- `ValidateTransaction`: validates the incoming banking transaction fields and adds `validated` plus `validation_errors`.
- `RiskAssess`: reads the complete event and adds `risk_level` plus `risk_reason`.
- `RouteTransaction`: writes the final JSON document to S3 and adds `route`, `s3_bucket`, `s3_key`, and `s3_uri`.

The state machine has exactly seven states: three Lambda Task states, one Choice state, two Succeed states, and one Fail state. The Choice state evaluates `$.risk_level`. Low-risk transactions finish in `Approved`, high-risk transactions finish in `ManualReview`, and invalid transactions finish in `InvalidTransaction`. Invalid transactions are still written to S3 before the Step Functions execution fails, which makes the failure auditable.

## Business Rules

A transaction is valid only when `amount` is numeric and greater than zero, `country` is a two-letter uppercase ISO-style code such as `MX` or `US`, `account` matches the `1234-5678` format, and both `transaction_id` and `merchant` are not empty. Valid transactions are high risk when `amount > 10000` or `country != "MX"`. Otherwise, they are low risk.

## Folder Structure

```text
.
├── README.md
├── versions.tf
├── variables.tf
├── main.tf
├── iam.tf
├── step_function.tf
├── outputs.tf
├── modules/
│   └── lambda_function/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── lambdas/
│   ├── validate_transaction/
│   │   └── lambda_function.py
│   ├── risk_assess/
│   │   └── lambda_function.py
│   └── route_transaction/
│       └── lambda_function.py
└── tests/
    ├── approved.json
    ├── review_amount.json
    ├── review_country.json
    └── invalid.json
```

## Run After Cloning

Clone the repository and enter the project directory:

```bash
git clone <YOUR_GITHUB_REPO_URL>
cd Act-tofu
```

Make sure you have these tools installed locally:

- Git
- OpenTofu `>= 1.6.0`
- AWS CLI
- Python 3.12

Configure AWS credentials on your machine before deploying. For example, if you use AWS CLI profiles:

```bash
aws configure
aws sts get-caller-identity
```

Initialize the project and validate the infrastructure:

```bash
tofu init
tofu fmt
tofu validate
```

Review the execution plan and deploy the stack:

```bash
tofu plan
tofu apply
```

If you want to use a different AWS region or a different resource prefix, you can override the defaults:

```bash
tofu plan -var="aws_region=us-east-1" -var="project_name=banking-transaction-processor"
```

## Useful Outputs

After deployment, you can inspect the most useful outputs with:

```bash
tofu output bucket_name
tofu output state_machine_arn
```

## GitHub Actions CI/CD

This project includes two manual GitHub Actions workflows that can be executed from the Actions tab with `Run workflow`.

- `Deploy and Test OpenTofu Pipeline`: deploys the infrastructure with OpenTofu, reads the generated outputs, starts the Step Function with the JSON files in `tests/`, waits briefly, and verifies the generated S3 objects.
- `Destroy OpenTofu Resources`: destroys the AWS resources created by OpenTofu. Run this workflow manually after the review or tests to avoid charges.

AWS credentials are not stored in the code and must be configured manually in GitHub as Repository Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TOFU_STATE_BUCKET`

The workflows use the project's default AWS region, `us-east-1`. The `TOFU_STATE_BUCKET` secret must contain the name of an existing S3 bucket used only for OpenTofu remote state. Create this bucket manually before running the deploy workflow, and do not use the same bucket that the project creates for transaction results.

The deploy and destroy workflows generate a temporary backend file inside GitHub Actions and initialize OpenTofu with the same remote state key: `banking-transaction-processor/terraform.tfstate`. This lets the destroy workflow find the resources created by the deploy workflow without forcing local `tofu init` commands to use the remote backend. Do not commit credentials, `.env` files, `.tfvars` files with secrets, or local OpenTofu/Terraform state files.

## Test With AWS CLI

Replace `<ARN>` with the `state_machine_arn` output:

```bash
aws stepfunctions start-execution --state-machine-arn <ARN> --input file://tests/approved.json
aws stepfunctions start-execution --state-machine-arn <ARN> --input file://tests/review_amount.json
aws stepfunctions start-execution --state-machine-arn <ARN> --input file://tests/review_country.json
aws stepfunctions start-execution --state-machine-arn <ARN> --input file://tests/invalid.json
```

The `invalid.json` execution is expected to end in the Fail state after the final JSON has been stored in S3 under the `invalid/` prefix.

## Verify S3 Results

Replace `<BUCKET_NAME>` with the `bucket_name` output:

```bash
aws s3 ls s3://<BUCKET_NAME> --recursive
```

Expected prefixes are:

- `approved/` for low-risk transactions.
- `review/` for high-risk transactions.
- `invalid/` for validation failures.

## Destroy

When the activity is complete, destroy all OpenTofu-managed resources:

```bash
tofu destroy
```

The S3 bucket uses `force_destroy = true`, so objects written by the pipeline are removed during destruction. This project intentionally avoids SNS, SQS, DynamoDB, API Gateway, and any manual AWS Console steps.
