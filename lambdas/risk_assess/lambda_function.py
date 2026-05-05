import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info("Assessing transaction risk")

    if not isinstance(event, dict):
        event = {"raw_event": event}

    if event.get("validated") is not True:
        event["risk_level"] = "invalid"
        event["risk_reason"] = "Validation failed"
        logger.info("Risk assessment completed. risk_level=invalid")
        return event

    amount = event.get("amount", 0)
    country = event.get("country", "")

    if amount > 10000:
        event["risk_level"] = "high"
        event["risk_reason"] = "Amount is greater than 10000"
    elif country != "MX":
        event["risk_level"] = "high"
        event["risk_reason"] = "Transaction country is outside MX"
    else:
        event["risk_level"] = "low"
        event["risk_reason"] = "Amount and country are within normal limits"

    logger.info("Risk assessment completed. risk_level=%s", event["risk_level"])
    return event
