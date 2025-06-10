# Experimental Confluent Enterprise Cluster Module with AWS PrivateLink

This directory contains an experimental Terraform module for creating a Confluent Enterprise Kafka cluster on AWS, with support for AWS PrivateLink.

**Note:** This is an experimental module and should not be used in production environments.

## Features

- Creates a Confluent Environment (if `existing_environment_id` is not provided).
- Deploys a Confluent Enterprise Kafka cluster on AWS.
- Configured for single-zone availability by default for the Kafka cluster.
- **Sets up AWS PrivateLink:**
  - Creates a `confluent_private_link_attachment`.
  - Creates an AWS VPC Endpoint (Interface Endpoint) in your specified VPC and subnets.
  - Configures a private Route 53 DNS zone for the PrivateLink connection.
  - Establishes a `confluent_private_link_attachment_connection`.
- Cluster name can be customized via the `cluster_name` variable.

## Prerequisites

- Terraform installed.
- Confluent Cloud API Key and Secret (set as `CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET` environment variables).
- AWS Credentials (set as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optionally `AWS_SESSION_TOKEN` environment variables with appropriate permissions).
- An existing AWS VPC.
- Subnet IDs within your VPC where the PrivateLink endpoint network interfaces will be deployed. You'll need to map Availability Zone IDs (e.g., `use1-az1`) to your Subnet IDs.

## Usage

1.  Navigate to this directory.
2.  (Optional) Create a `terraform.tfvars` file to provide necessary variable values. Example:
    ```terraform
    aws_region             = "us-east-1"
    cluster_name           = "my-secure-enterprise-cluster"
    aws_account_id         = "123456789012" // Your AWS Account ID
    vpc_id                 = "vpc-0abcdef1234567890" // Your VPC ID
    subnets_to_privatelink = {
      "use1-az1" = "subnet-0123456789abcdef0" // Map AZ ID to your Subnet ID
      "use1-az2" = "subnet-fedcba9876543210"  // Map AZ ID to your Subnet ID
    }
    // To use an existing environment:
    // existing_environment_id = "env-xxxxx"
    ```
3.  Initialize Terraform:
    ```bash
    terraform init
    ```
4.  Apply the Terraform configuration:
    ```bash
    terraform apply
    ```

## Inputs

| Name                       | Description                                                                                                | Type        | Default                   | Required |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------- | ------------------------- | :------: |
| `aws_region`               | The AWS region for provider and resources.                                                                 | `string`    | `us-east-1`               |    no    |
| `cluster_name`             | The name for the Kafka Cluster.                                                                            | `string`    | `jibarra_test_enterprise` |    no    |
| `existing_environment_id`  | Optional: The ID of an existing Confluent Environment. If provided, a new one is not created. | `string`    | `""`                      |    no    |
| `aws_account_id`           | The AWS Account ID where the PrivateLink endpoint will be created (e.g., 123456789012).                   | `string`    |                           |   yes    |
| `vpc_id`                   | The ID of the AWS VPC in which the PrivateLink endpoint will be created.                                     | `string`    |                           |   yes    |
| `subnets_to_privatelink`   | A map of Zone IDs to Subnet IDs for the AWS PrivateLink endpoint (e.g., `{"use1-az1" = "subnet-..."}`). | `map(string)` |                           |   yes    |

## Outputs

| Name                                       | Description                                                              |
| ------------------------------------------ | ------------------------------------------------------------------------ |
| `kafka_cluster_id`                         | The ID of the created Kafka Cluster.                                     |
| `kafka_bootstrap_endpoint`                 | The bootstrap endpoint for the Kafka cluster.                            |
| `private_link_attachment_id`               | The ID of the Confluent Private Link Attachment.                         |
| `private_link_attachment_dns_domain`       | The DNS domain of the Confluent Private Link Attachment.                 |
| `private_link_aws_vpc_endpoint_service_name` | The AWS VPC Endpoint Service Name for the PLA.                           |
| `private_link_aws_vpc_endpoint_id`         | The ID of the AWS VPC Endpoint created for the PrivateLink connection.   |
