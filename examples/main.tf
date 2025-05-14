module "vpc" {
  source = "./modules/vpc"  # Path to the module source (local)

  name = "networking"  # Name for the VPC and tag for resources

  cidr = "10.0.0.0/16"  # VPC CIDR block

  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]  # List of availability zones. Defaults to AWS region using data source if not specified.

  public = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]  # CIDR blocks for public subnets

  private = ["10.0.13.0/24", "10.0.14.0/24", "10.0.15.0/24"]  # CIDR blocks for private subnets

  private_ip_map = false  # Assign public IPs to instances in private subnets (defaults to false)

  instance_tenancy = "default"  # Instance hardware (default for shared hardware)

  enable_dns_support = true  # Enable DNS resolution within VPC

  enable_dns_hostnames = true  # Enable DNS hostnames for instances

  ingress = ["ssh", "http", "https"]  # Allowed ingress traffic types (ssh, http, https)
}
