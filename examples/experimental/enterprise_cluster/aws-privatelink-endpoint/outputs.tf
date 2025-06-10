output "vpc_endpoint_id" {
  description = "The ID of the created AWS VPC Endpoint."
  value       = aws_vpc_endpoint.privatelink.id
}

output "created_subnet_ids" {
  description = "IDs of the AWS subnets created by this submodule."
  value       = [for subnet in aws_subnet.privatelink_subnet : subnet.id]
}
