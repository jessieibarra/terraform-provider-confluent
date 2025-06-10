variable "vpc_id" {
  description = "The VPC ID to private link to Confluent Cloud."
  type        = string
}

variable "privatelink_service_name" {
  description = "The Service Name from Confluent Cloud to Private Link with (provided by confluent_private_link_attachment)."
  type        = string
}

variable "dns_domain" {
  description = "The root DNS domain for the Private Link Attachment (e.g., `pr123a.us-east-2.aws.confluent.cloud`), provided by confluent_private_link_attachment."
  type        = string
}

variable "subnets_to_privatelink" {
  description = "A map of Zone IDs to Subnet IDs (e.g.: {\"use1-az1\" = \"subnet-abcdef0123456789a\", ...})."
  type        = map(string)
}

variable "aws_region" {
  description = "AWS region for resources in this submodule."
  type        = string
}
