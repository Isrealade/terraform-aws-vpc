````markdown
# Full VPC Example

This example demonstrates how to use the VPC module to create:

- A VPC with public and private subnets across multiple Availability Zones
- NAT Gateways and Internet Gateway
- Route tables for public and private subnets
- Security groups with common ingress rules (SSH, HTTP, HTTPS, PostgreSQL)
- Optional DB Subnet Group for RDS/Aurora
- Gateway and Interface VPC Endpoints (S3, EC2, SSM)
- Custom tags applied to all resources

---

## Usage

```hcl
module "vpc" {
  source  = "../../"  # Path to your VPC module

  name = "example-vpc"
  cidr = "10.10.0.0/16"

  public_subnet  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet = ["10.10.3.0/24", "10.10.4.0/24"]

  create_db_subnet  = true
  subnet_group_name = "example-db-subnet-group"

  create_endpoint = true
  vpc_endpoints = {
    gateway = [
      { service_name = "s3", ip_address_type = "ipv4", policy = "" }
    ]
    interface = [
      { service_name = "ec2", subnet_ids = [], security_group_ids = [], private_dns_enabled = true },
      { service_name = "ssm", subnet_ids = [], security_group_ids = [], private_dns_enabled = true }
    ]
  }

  ingress = ["ssh", "http", "https", "postgresql"]

  tags = {
    Environment = "example"
    Project     = "full-vpc"
  }
}
````

---

## Notes

* When using `count` to create public or private subnets, **avoid mixing with manual CIDR blocks** unless you account for `subnet_newbits` to prevent CIDR conflicts.
* Interface endpoints default to the first private subnet in each AZ if `subnet_ids` are not provided.
* Security group defaults can be extended using `custom_ingress`.
* DB Subnet Group is optional; enable with `create_db_subnet = true`.