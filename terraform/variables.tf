variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to"
  type        = string
  default     = "<your region>"
}

variable "environment" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project, used as a prefix for resources"
  type        = string
  default     = "cert-approval"
}
