output "kafka_cluster_id" {
  description = "The ID of the created Confluent Kafka Cluster."
  value       = confluent_kafka_cluster.enterprise_test.id
}

output "kafka_bootstrap_endpoint" {
  description = "The bootstrap endpoint for the Kafka cluster."
  value       = confluent_kafka_cluster.enterprise_test.bootstrap_endpoint
}

output "private_link_attachment_id" {
  description = "The ID of the Confluent Private Link Attachment."
  value       = confluent_private_link_attachment.experimental_pla.id
}

output "private_link_attachment_dns_domain" {
  description = "The DNS domain of the Confluent Private Link Attachment (used for private DNS)."
  value       = confluent_private_link_attachment.experimental_pla.dns_domain
}

output "private_link_aws_vpc_endpoint_service_name" {
  description = "The AWS VPC Endpoint Service Name for the Confluent Private Link Attachment."
  value       = confluent_private_link_attachment.experimental_pla.aws[0].vpc_endpoint_service_name
}

output "private_link_aws_vpc_endpoint_id" {
  description = "The ID of the AWS VPC Endpoint created for the PrivateLink connection."
  value       = module.aws_vpc_endpoint_service.vpc_endpoint_id
}

// Placeholder for other outputs
// This is an experimental module.
