terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.31.0" // Using the version found in existing examples
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" // A recent, stable version
    }
  }
}

provider "confluent" {
  // Credentials are expected to be set via environment variables:
  // CONFLUENT_CLOUD_API_KEY
  // CONfluent_CLOUD_API_SECRET
}

provider "aws" {
  region = var.aws_region
  // Credentials are expected to be set via environment variables:
  // AWS_ACCESS_KEY_ID
  // AWS_SECRET_ACCESS_KEY
  // AWS_SESSION_TOKEN (optional)
}

locals {
  create_new_environment   = var.existing_environment_id == null || var.existing_environment_id == ""
  effective_environment_id = local.create_new_environment ? confluent_environment.experimental_env[0].id : var.existing_environment_id
}

resource "confluent_environment" "experimental_env" {
  count        = local.create_new_environment ? 1 : 0
  display_name = "Experimental Environment for Enterprise Cluster"
  // Add any other required or relevant attributes for the environment.
  // For now, a simple environment with just a display name will be created.
}

resource "confluent_kafka_cluster" "enterprise_test" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.aws_region
  environment {
    id = local.effective_environment_id
  }
  enterprise {
    cku = 1 // Assuming 1 CKU is the smallest. This might need adjustment.
  }
  // Standard Kafka cluster configuration can be added here if needed
  // For now, focusing on the enterprise block for CKUs.
}

resource "confluent_private_link_attachment" "experimental_pla" {
  display_name = "${var.cluster_name}-pla"
  cloud        = "AWS"
  region       = var.aws_region
  environment {
    id = local.effective_environment_id
  }
  // AWS specific configurations will be implicitly handled by the provider
  // based on the 'cloud = "AWS"' attribute.
}

module "aws_vpc_endpoint_service" {
  source = "./aws-privatelink-endpoint"

  vpc_id                      = var.vpc_id
  aws_region                  = var.aws_region
  availability_zone_names     = var.availability_zone_names // UPDATED
  subnet_cidr_blocks          = var.subnet_cidr_blocks      // UPDATED
  privatelink_service_name    = confluent_private_link_attachment.experimental_pla.aws[0].vpc_endpoint_service_name
  dns_domain                  = confluent_private_link_attachment.experimental_pla.dns_domain

  depends_on = [confluent_private_link_attachment.experimental_pla]
}

resource "confluent_private_link_attachment_connection" "experimental_plac" {
  display_name = "${var.cluster_name}-plac"
  environment {
    id = local.effective_environment_id
  }
  private_link_attachment {
    id = confluent_private_link_attachment.experimental_pla.id
  }
  aws {
    vpc_endpoint_id = module.aws_vpc_endpoint_service.vpc_endpoint_id
  }
  depends_on = [
    confluent_private_link_attachment.experimental_pla,
    module.aws_vpc_endpoint_service
  ]
}

// Placeholder for Confluent Enterprise Cluster resources
// This is an experimental module.
