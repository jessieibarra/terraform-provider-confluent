// AWS Provider configuration for this submodule
// It will inherit from the parent module's provider configuration if not specified,
// or we can define it explicitly if needed for clarity or specific versioning.
// For now, let's assume provider inheritance.

data "aws_vpc" "privatelink" {
  id = var.vpc_id
}

data "aws_availability_zone" "privatelink" {
  for_each = var.subnets_to_privatelink
  zone_id  = each.key // Zone ID like use1-az1
}

locals {
  // Extract the network ID part from the DNS domain for unique naming
  // e.g., from rplcs.us-west-2.aws.confluent.cloud -> rplcs
  network_id_parts = split(".", var.dns_domain)
  network_id       = length(local.network_id_parts) > 0 ? local.network_id_parts[0] : "defaultnetid"
}

resource "aws_security_group" "privatelink" {
  name        = "ccloud-privatelink-${local.network_id}-${var.vpc_id}"
  description = "Confluent Cloud Private Link minimal security group for ${var.dns_domain} in ${var.vpc_id}"
  vpc_id      = data.aws_vpc.privatelink.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    // Port for Kafka brokers
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  // Standard Kafka port for Schema Registry when using PLA
  ingress {
    from_port   = 443 // Schema Registry typically uses 443 over PLA
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
    description = "Allow Schema Registry HTTPS"
  }

  // Egress can be kept default (allow all) or restricted as needed.
  // The example didn't specify egress, so keeping it default.

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Confluent PrivateLink SG"
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id              = data.aws_vpc.privatelink.id
  service_name        = var.privatelink_service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink.id]
  subnet_ids          = values(var.subnets_to_privatelink) // Use values from the map
  private_dns_enabled = false // DNS will be handled by Route 53 private hosted zone

  tags = {
    Name = "Confluent PrivateLink Endpoint"
  }
}

resource "aws_route53_zone" "privatelink" {
  name = var.dns_domain

  vpc {
    vpc_id     = data.aws_vpc.privatelink.id
    vpc_region = var.aws_region // Required for private hosted zones associated with VPCs in different regions
  }

  tags = {
    Name = "Confluent PrivateLink DNS Zone"
  }
}

// Create a wildcard CNAME record for the general domain to one of the VPC endpoint DNS names
resource "aws_route53_record" "privatelink_wildcard" {
  // Only create this if there's more than one subnet, otherwise zonal record handles '*'
  count   = length(var.subnets_to_privatelink) == 1 ? 0 : 1
  zone_id = aws_route53_zone.privatelink.id
  name    = "*. ${aws_route53_zone.privatelink.name}"
  type    = "CNAME"
  ttl     = 60
  records = [
    // aws_vpc_endpoint.privatelink.dns_entry is a list of objects,
    // each with a dns_name. We typically use the first one for the wildcard.
    aws_vpc_endpoint.privatelink.dns_entry[0].dns_name
  ]
}

locals {
  // Example: vpce-0123456789abcdef0-xyzalpha.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
  // We need "vpce-0123456789abcdef0-xyzalpha"
  endpoint_dns_prefix = split(".", aws_vpc_endpoint.privatelink.dns_entry[0].dns_name)[0]
}

// Create zonal CNAME records
// *.zoneid.dns_domain -> zonal DNS name of VPC endpoint
resource "aws_route53_record" "privatelink_zonal" {
  for_each = var.subnets_to_privatelink

  zone_id = aws_route53_zone.privatelink.id
  // If only one subnet, make it *.dns_domain, otherwise *.zoneid.dns_domain
  name    = length(var.subnets_to_privatelink) == 1 ? "*. ${aws_route53_zone.privatelink.name}" : "*. ${each.key}.${aws_route53_zone.privatelink.name}"
  type    = "CNAME"
  ttl     = 60
  records = [
    // Construct the zonal DNS name for the VPC endpoint.
    // Example: vpce-0123456789abcdef0-xyzalpha-us-west-2a.vpce-svc-0123456789abcdef0.us-west-2.vpce.amazonaws.com
    // Need to find the correct DNS entry that corresponds to the AZ.
    // The order of dns_entry might not directly map to subnet_ids order.
    // A safer way is to use the AZ name from data.aws_availability_zone.
    // Format: ${endpoint_dns_prefix_from_dns_entry}.${az_name}.${rest_of_dns_entry}
    // However, the reference example format is slightly different:
    // format("%s-%s%s", local.endpoint_prefix, data.aws_availability_zone.privatelink[each.key].name, replace(aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"], local.endpoint_prefix, ""))
    // This seems to construct it based on the AZ *name* (e.g. us-east-1a) rather than AZ *ID* (e.g. use1-az1)
    // Let's use the AZ name.
    format("%s-%s%s",
      local.endpoint_dns_prefix,
      data.aws_availability_zone.privatelink[each.key].name, // e.g., us-east-1a
      replace(aws_vpc_endpoint.privatelink.dns_entry[0].dns_name, local.endpoint_dns_prefix, "")
    )
  ]
}
