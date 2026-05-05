variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name the AWS resources for this academic activity."
  type        = string
  default     = "banking-transaction-processor"
}
