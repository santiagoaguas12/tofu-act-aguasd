import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _is_not_empty_string(value):
    return isinstance(value, str) and value.strip() != ""


def lambda_handler(event, context):
    logger.info("Validating transaction")

    if not isinstance(event, dict):
        event = {"raw_event": event}

    errors = []

    amount = event.get("amount")
    if isinstance(amount, bool) or not isinstance(amount, (int, float)) or amount <= 0:
        errors.append("amount must be numeric and greater than 0")

    country = event.get("country")
    if not isinstance(country, str) or re.fullmatch(r"[A-Z]{2}", country) is None:
        errors.append("country must be a 2-letter uppercase ISO code")

    account = event.get("account")
    if not isinstance(account, str) or re.fullmatch(r"\d{4}-\d{4}", account) is None:
        errors.append("account must have format 1234-5678")

    if not _is_not_empty_string(event.get("transaction_id")):
        errors.append("transaction_id must not be empty")

    if not _is_not_empty_string(event.get("merchant")):
        errors.append("merchant must not be empty")

    event["validated"] = len(errors) == 0
    event["validation_errors"] = errors

    logger.info("Validation completed. valid=%s errors=%s", event["validated"], len(errors))
    return event
