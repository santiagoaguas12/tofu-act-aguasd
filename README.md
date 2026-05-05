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

## Deploy

Run these commands from the project root:

```bash
tofu init
tofu fmt
tofu validate
tofu plan
tofu apply
```

Useful outputs are available after deployment:

```bash
tofu output bucket_name
tofu output state_machine_arn
```

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
