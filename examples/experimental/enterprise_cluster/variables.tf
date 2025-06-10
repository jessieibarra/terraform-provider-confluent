variable "aws_region" {
  description = "The AWS region for provider and resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "The AWS Account ID where the PrivateLink endpoint will be created. (e.g., 123456789012)"
  type        = string
  // No default, as this is specific to the user's environment
}

variable "vpc_id" {
  description = "The ID of the AWS VPC in which the PrivateLink endpoint will be created."
  type        = string
  // No default, as this is specific to the user's environment
}

variable "availability_zone_names" {
  description = "A list of Availability Zone names where subnets for the PrivateLink endpoint will be created (e.g., [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)
  // No default, user must specify.
}

variable "subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the new subnets, corresponding to the order of availability_zone_names. Must be within the VPC's CIDR range and non-overlapping. (e.g., [\"10.0.1.0/24\", \"10.0.2.0/24\"])"
  type        = list(string)
  // No default, user must specify.
}

variable "cluster_name" {
  description = "The name for the Confluent Kafka Cluster."
  type        = string
  default     = "jibarra_test_enterprise"
}

variable "existing_environment_id" {
  description = "Optional: The ID of an existing Confluent Environment to use. If provided, a new environment will not be created. If omitted or empty, a new environment will be created by the module."
  type        = string
  default     = "" // Using an empty string as a clear indicator for 'not provided'
}

// Placeholder for other input variables
// This is an experimental module.
