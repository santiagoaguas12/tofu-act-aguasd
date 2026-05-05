import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client("s3")


def _prefix_for_risk(risk_level):
    if risk_level == "low":
        return "approved"
    if risk_level == "high":
        return "review"
    return "invalid"


def lambda_handler(event, context):
    logger.info("Routing transaction")

    if not isinstance(event, dict):
        event = {"raw_event": event}

    bucket_name = os.environ["BUCKET_NAME"]
    route = _prefix_for_risk(event.get("risk_level"))
    transaction_id = event.get("transaction_id") or "unknown-transaction"
    s3_key = f"{route}/{transaction_id}.json"

    event["route"] = route
    event["s3_bucket"] = bucket_name
    event["s3_key"] = s3_key
    event["s3_uri"] = f"s3://{bucket_name}/{s3_key}"

    s3_client.put_object(
        Bucket=bucket_name,
        Key=s3_key,
        Body=json.dumps(event, indent=2, sort_keys=True),
        ContentType="application/json",
    )

    logger.info("Transaction stored at %s", event["s3_uri"])
    return event
