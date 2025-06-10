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

variable "availability_zone_names" {
  description = "A list of Availability Zone names where subnets for the PrivateLink endpoint will be created."
  type        = list(string)
}

variable "subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the new subnets, corresponding to the order of availability_zone_names."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region for resources in this submodule."
  type        = string
}
