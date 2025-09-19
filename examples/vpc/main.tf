provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "../../"

  name = "example-vpc"
  cidr = "10.10.0.0/16"

  # AZs (optional)
  azs = ["us-east-1a", "us-east-1b"]

  # Public and private subnets
  public_subnet  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet = ["10.10.3.0/24", "10.10.4.0/24"]

  # Subnet auto-CIDR controls (only needed when using *_count)
  # private_subnet_offset = 64

  # Private subnets will not have public IPs
  private_ip_map = false

  # DB Subnet Group
  create_db_subnet  = true
  subnet_group_name = "example-db-subnet-group"

  # Security group ingress
  ingress = ["ssh", "http", "https", "postgresql"]

  # NAT strategy
  enable_nat     = true
  single_nat     = true      # one NAT Gateway for all private subnets
  one_nat_per_az = false     # set true (and single_nat=false) for per-AZ NAT

  # Endpoints
  create_endpoint = true
  vpc_endpoints = {
    gateway = [
      {
        service_name    = "s3"
        ip_address_type = "ipv4"
        policy          = ""
        tags            = { Team = "networking" }
      }
    ]
    interface = [
      {
        service_name        = "ec2"
        subnet_ids          = [] # defaults to private subnets
        security_group_ids  = [] # defaults to VPC SG
        private_dns_enabled = true
        tags                 = { Owner = "platform" }
      },
      {
        service_name        = "ssm"
        private_dns_enabled = true
        tags                 = { ManagedBy = "terraform" }
      }
    ]
  }

  # Default tags applied to all endpoints of each type
  gateway_endpoints_default_tags   = { Environment = "example" }
  interface_endpoints_default_tags = { Environment = "example" }

  tags = {
    Environment = "example"
    Project     = "full-vpc"
  }
}