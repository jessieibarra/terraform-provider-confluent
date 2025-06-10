data "aws_vpc" "privatelink" {
  id = var.vpc_id
}

// Create a map from AZ names to CIDR blocks for easier iteration
locals {
  az_to_cidr_map = zipmap(var.availability_zone_names, var.subnet_cidr_blocks)
}

resource "aws_subnet" "privatelink_subnet" {
  for_each = local.az_to_cidr_map

  vpc_id            = data.aws_vpc.privatelink.id
  cidr_block        = each.value // The CIDR block for this subnet
  availability_zone = each.key   // The AZ name like "us-east-1a"

  tags = {
    Name = "Confluent PrivateLink Subnet (${each.key})"
    // Add any other tags required by the user/organization
  }
}

// This data source is still useful for getting AZ IDs if needed by other resources,
// or for consistency if other parts of the config use AZ IDs.
// However, aws_subnet directly takes AZ names.
data "aws_availability_zone" "privatelink_az_details" {
  for_each = local.az_to_cidr_map // Iterate using the same map
  name     = each.key             // Get details by AZ name
}

locals {
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
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
    description = "Allow Schema Registry HTTPS"
  }

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
  // Use the IDs of the newly created subnets
  subnet_ids          = [for subnet in aws_subnet.privatelink_subnet : subnet.id]
  private_dns_enabled = false

  tags = {
    Name = "Confluent PrivateLink Endpoint"
  }

  // Ensure subnets are created before the endpoint
  depends_on = [aws_subnet.privatelink_subnet]
}

resource "aws_route53_zone" "privatelink" {
  name = var.dns_domain

  vpc {
    vpc_id     = data.aws_vpc.privatelink.id
    vpc_region = var.aws_region
  }

  tags = {
    Name = "Confluent PrivateLink DNS Zone"
  }
}

locals {
  endpoint_dns_prefix = split(".", aws_vpc_endpoint.privatelink.dns_entry[0].dns_name)[0]
  // Create a map of AZ name to the corresponding created subnet resource
  // This local variable is not strictly used in the HCL below but can be useful for debugging or extensions.
  // az_name_to_subnet_map = { for subnet in aws_subnet.privatelink_subnet : subnet.availability_zone => subnet }
}

// Create a wildcard CNAME record for the general domain
resource "aws_route53_record" "privatelink_wildcard" {
  // Only create this if there's more than one AZ/subnet, otherwise zonal record handles '*'
  count   = length(var.availability_zone_names) <= 1 ? 0 : 1
  zone_id = aws_route53_zone.privatelink.id
  name    = "*.${aws_route53_zone.privatelink.name}"
  type    = "CNAME"
  ttl     = 60
  records = [
    aws_vpc_endpoint.privatelink.dns_entry[0].dns_name
  ]
  depends_on = [aws_vpc_endpoint.privatelink]
}

// Create zonal CNAME records: *.zone_name.dns_domain -> zonal DNS name of VPC endpoint
resource "aws_route53_record" "privatelink_zonal" {
  for_each = local.az_to_cidr_map // Iterate over the same map used for subnets

  zone_id = aws_route53_zone.privatelink.id
  // Name format: *.us-east-1a.rplcs.us-west-2.aws.confluent.cloud or *.rplcs.us-west-2.aws.confluent.cloud if single AZ
  name    = length(var.availability_zone_names) == 1 ? "*.${aws_route53_zone.privatelink.name}" : "*.${each.key}.${aws_route53_zone.privatelink.name}"
  type    = "CNAME"
  ttl     = 60
  records = [
    // Construct the zonal DNS name for the VPC endpoint.
    // The VPC endpoint DNS entries are per AZ. We need to find the one matching the current AZ.
    // The expression `one([for entry in aws_vpc_endpoint.privatelink.dns_entry : entry.dns_name if contains(entry.dns_name, data.aws_availability_zone.privatelink_az_details[each.key].name_suffix )])`
    // attempts to find the DNS entry corresponding to the current availability zone's suffix (e.g., '1a' for 'us-east-1a').
    // This relies on name_suffix being unique enough within the dns_entry strings.
    // Example AZ name: us-east-1a -> name_suffix: 1a
    // Example dns_entry: vpce-0123-us-east-1a.vpce-svc-4567.us-east-1.vpce.amazonaws.com
    one([for entry in aws_vpc_endpoint.privatelink.dns_entry : entry.dns_name if contains(entry.dns_name, replace(data.aws_availability_zone.privatelink_az_details[each.key].name, var.aws_region, "") )])
  ]
  // Ensure VPC endpoint and AZ details are available before trying to access its dns_entry and name_suffix
  depends_on = [aws_vpc_endpoint.privatelink, aws_availability_zone.privatelink_az_details]
}
