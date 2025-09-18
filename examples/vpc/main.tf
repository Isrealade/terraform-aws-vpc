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

  # Private subnets will not have public IPs
  private_ip_map = false

  # DB Subnet Group
  create_db_subnet  = true
  subnet_group_name = "example-db-subnet-group"

  # Security group ingress
  ingress = ["ssh", "http", "https", "postgresql"]

  # Endpoints
  create_endpoint = true
  vpc_endpoints = {
    gateway = [
      {
        service_name    = "s3"
        ip_address_type = "ipv4"
        policy          = ""
      }
    ]
    interface = [
      {
        service_name        = "ec2"
        subnet_ids          = [] # defaults to private subnets
        security_group_ids  = [] # defaults to VPC SG
        private_dns_enabled = true
      },
      {
        service_name        = "ssm"
        private_dns_enabled = true
      }
    ]
  }

  tags = {
    Environment = "example"
    Project     = "full-vpc"
  }
}