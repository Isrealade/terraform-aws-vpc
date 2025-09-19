````markdown
# Full VPC Example

This example demonstrates how to use the VPC module to create:

- A VPC with public and private subnets across multiple Availability Zones
- Internet Gateway and NAT Gateways (single NAT by default; optional per‑AZ NAT)
- Single public route table; private route tables per‑AZ
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

  # NAT strategy
  enable_nat     = true
  single_nat     = true
  one_nat_per_az = false

  create_endpoint = true
  vpc_endpoints = {
    gateway = [
      { service_name = "s3", ip_address_type = "ipv4", policy = "", tags = { Team = "networking" } }
    ]
    interface = [
      { service_name = "ec2", subnet_ids = [], security_group_ids = [], private_dns_enabled = true, tags = { Owner = "platform" } },
      { service_name = "ssm", subnet_ids = [], security_group_ids = [], private_dns_enabled = true, tags = { ManagedBy = "terraform" } }
    ]
  }

  # Default endpoint tags for all endpoints of each type
  gateway_endpoints_default_tags   = { Environment = "example" }
  interface_endpoints_default_tags = { Environment = "example" }

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