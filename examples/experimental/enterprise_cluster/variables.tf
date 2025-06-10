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

variable "subnets_to_privatelink" {
  description = "A map of Zone IDs to Subnet IDs for the AWS PrivateLink endpoint network interfaces. Example: { \"use1-az1\" = \"subnet-abcdef0123456789a\", \"use1-az2\" = \"subnet-bcdefg0123456789b\" }"
  type        = map(string)
  // No default, as this is specific to the user's environment
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
