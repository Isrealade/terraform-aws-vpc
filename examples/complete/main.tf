provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../.."

  name = "complete-vpc"
  cidr = "10.0.0.0/16"

  # Specify exact AZs
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Create subnets in all specified AZs
  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  # VPC settings
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Subnet settings
  private_ip_map = false

  # Security group settings
  ingress = ["ssh", "http", "https"]

  # Tags for all resources
  tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}

# Output the VPC ID and subnet IDs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.vpc.security_group_id
} 