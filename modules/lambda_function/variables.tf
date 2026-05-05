variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Directory that contains the Python Lambda source code."
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN used by the Lambda function."
  type        = string
}

variable "runtime" {
  description = "Runtime used by the Lambda function."
  type        = string
}

variable "handler" {
  description = "Lambda handler."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function."
  type        = map(string)
  default     = {}
}
