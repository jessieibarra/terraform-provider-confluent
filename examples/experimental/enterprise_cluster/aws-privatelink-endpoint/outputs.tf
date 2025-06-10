output "vpc_endpoint_id" {
  description = "The ID of the created AWS VPC Endpoint."
  value       = aws_vpc_endpoint.privatelink.id
}
