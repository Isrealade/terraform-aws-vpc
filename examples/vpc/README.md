   # VPC Example

   This directory contains an example of how to use the AWS VPC Terraform module.

   ## Usage

   1. **Configure AWS Provider**: Ensure you have your AWS credentials configured.
   2. **Initialize Terraform**: Run `terraform init` to initialize the working directory.
   3. **Plan the Deployment**: Run `terraform plan` to see the resources that will be created.
   4. **Apply the Configuration**: Run `terraform apply` to create the resources.

   ## Requirements

   - Terraform version >= 1.0.0
   - AWS provider version >= 4.0

   ## Providers

   - `aws`: The AWS provider is required to manage AWS resources.

   ## Modules

   - `vpc`: This module creates a complete VPC infrastructure, including subnets, NAT Gateways, and security groups.

   ## Outputs

   - `vpc_id`: The ID of the created VPC.
   - `public_subnet_ids`: List of public subnet IDs.
   - `private_subnet_ids`: List of private subnet IDs.
