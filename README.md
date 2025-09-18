# AWS VPC Terraform Module

This Terraform module creates a fully-featured **VPC infrastructure** on AWS, including:

* Public and private subnets across multiple Availability Zones (AZs)
* Internet Gateway and NAT Gateways (with per-AZ NAT for private subnets)
* Route tables for public (per-AZ) and private subnets
* Security groups with predefined and custom ingress rules
* Optional DB subnet group for RDS/Aurora
* Optional Gateway and Interface VPC Endpoints
* Custom tagging support on all resources

The module is highly configurable and suitable for **single-AZ and multi-AZ production environments**.

---

## Key Features

* Create a VPC with a configurable CIDR block
* Auto-generate public/private subnets with `subnet_newbits` or provide your own CIDRs
* Internet Gateway for public subnets
* NAT Gateways for private subnets (per-AZ deployment for HA)
* Route tables for public (per-AZ) and private subnets
* Security groups with predefined and custom ingress rules
* Optional DB Subnet Group
* Optional Gateway and Interface VPC Endpoints
* Custom tags for all resources

**⚠️ Note on Subnet Creation:**
When using `count` to auto-generate subnets, Terraform calculates CIDRs using `subnet_newbits` (default = 8). Avoid specifying both `public_subnet`/`private_subnet` and `*_subnet_count` at the same time to prevent CIDR conflicts. You can also manually provide subnet CIDRs based on your `subnet_newbits` calculation.

---

## Usage Examples

### 1. Simple VPC with Auto-Generated Subnets

```hcl
module "vpc" {
  source = "Isrealade/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  # Automatically create 2 public and 2 private subnets
  public_subnet_count  = 2
  private_subnet_count = 2
  
  ingress = ["ssh", "http", "https"]
}
```

> Terraform automatically calculates subnet CIDRs using `subnet_newbits`. Avoid providing both subnet lists and counts.

---

### 2. VPC with Custom Subnet CIDRs and Multi-AZ NAT

```hcl
module "vpc" {
  source = "Isrealade/vpc/aws"

  name = "production-vpc"
  cidr = "10.1.0.0/16"
  
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]

  private_ip_map       = false
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  ingress = ["ssh", "http", "https"]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

> Public subnets now have **per-AZ route tables** for better scalability and fault isolation. NAT Gateways are deployed one per AZ.

---

### 3. VPC with DB Subnet Group

```hcl
module "vpc" {
  source = "Isrealade/vpc/aws"

  name = "db-vpc"
  cidr = "10.2.0.0/16"

  public_subnet  = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet = ["10.2.3.0/24", "10.2.4.0/24"]

  create_db_subnet  = true
  subnet_group_name = "my-db-subnet-group"
  
  db_subnet_group_tags = {
    Environment = "production"
    Purpose     = "RDS"
  }

  ingress = ["ssh", "postgresql"]
}
```

> Only create DB Subnet Group if you have at least one private subnet.

---

### 4. VPC with Gateway and Interface Endpoints

```hcl
module "vpc" {
  source = "Isrealade/vpc/aws"

  name = "endpoint-vpc"
  cidr = "10.3.0.0/16"

  public_subnet  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet = ["10.3.3.0/24", "10.3.4.0/24"]

  create_endpoint = true

  vpc_endpoints = {
    interface = [
      {
        service_name        = "ec2"
        subnet_ids          = [] # Defaults to module private subnets (per-AZ)
        security_group_ids  = [] # Defaults to VPC SG
        private_dns_enabled = true
      },
      {
        service_name        = "ssm"
        subnet_ids          = []
        security_group_ids  = []
        private_dns_enabled = true
      }
    ]

    gateway = [
      {
        service_name    = "s3"
        ip_address_type = "ipv4"
        policy          = ""
      }
    ]
  }

  ingress = ["ssh", "https"]
}
```

> Interface endpoints pick **one private subnet per AZ by default** if `subnet_ids` is empty. Gateway endpoints are regional and tagged per module configuration.

---

## Inputs

| Name                   | Description                                              | Type           | Default | Required |
| ---------------------- | -------------------------------------------------------- | -------------- | ------- | :------: |
| name                   | Name tag for all resources                               | `string`       | n/a     |    yes   |
| cidr                   | VPC CIDR block                                           | `string`       | n/a     |    yes   |
| azs                    | Availability zones                                       | `list(string)` | `[]`    |    no    |
| public\_subnet         | List of public subnet CIDRs                              | `list(string)` | `[]`    |    no    |
| public\_subnet\_count  | Number of public subnets if CIDRs not provided           | `number`       | 0       |    no    |
| private\_subnet        | List of private subnet CIDRs                             | `list(string)` | `[]`    |    no    |
| private\_subnet\_count | Number of private subnets if CIDRs not provided          | `number`       | 0       |    no    |
| subnet\_newbits        | Bits to increment subnet size for auto-generated subnets | `number`       | 8       |    no    |
| create\_db\_subnet     | Create a DB subnet group                                 | `bool`         | false   |    no    |
| create\_endpoint       | Create Gateway or Interface endpoints                    | `bool`         | false   |    no    |
| vpc\_endpoints         | Object for Gateway and Interface endpoints               | `object`       | `{}`    |    no    |
| ingress                | Predefined ingress rules                                 | `list(string)` | `[]`    |    no    |
| custom\_ingress        | Custom ingress rules                                     | `list(object)` | `[]`    |    no    |
| tags                   | Map of tags for all resources                            | `map(string)`  | `{}`    |    no    |

---

## Outputs

| Name                                       | Description                                                |
| ------------------------------------------ | ---------------------------------------------------------- |
| vpc\_id                                    | VPC ID                                                     |
| availability\_zones                        | List of AZs used                                           |
| public\_subnet\_ids                        | List of public subnet IDs                                  |
| public\_subnet\_map                        | Map of index to public subnet IDs                          |
| private\_subnet\_ids                       | List of private subnet IDs                                 |
| private\_subnet\_map                       | Map of index to private subnet IDs                         |
| nat\_gateway\_ids                          | List of NAT Gateway IDs                                    |
| nat\_gateway\_public\_ips                  | List of NAT Gateway public IPs                             |
| nat\_gateway\_ips\_map                     | Indexed map of NAT Gateway public IPs                      |
| elastic\_ip\_ids                           | List of Elastic IP IDs associated with NATs                |
| nat\_gateway\_subnet\_ids                  | List of subnets where NAT Gateways are deployed            |
| internet\_gateway\_id                      | Internet Gateway ID                                        |
| public\_route\_table\_ids                  | Map of AZ to public route table ID (per-AZ public subnets) |
| public\_subnet\_route\_table\_map          | Map of public subnet ID to its route table ID              |
| private\_route\_table\_ids                 | Map of index to private route table IDs                    |
| security\_group\_id                        | Main VPC security group ID                                 |
| db\_subnet\_group\_id                      | DB Subnet Group ID (empty if not created)                  |
| db\_subnet\_group\_subnet\_ids             | Subnets included in DB Subnet Group                        |
| gateway\_endpoint\_ids                     | Gateway endpoint IDs                                       |
| gateway\_endpoint\_services                | Gateway endpoint service names                             |
| interface\_endpoint\_ids                   | Interface endpoint IDs                                     |
| interface\_endpoint\_subnet\_ids           | Subnets used by interface endpoints                        |
| interface\_endpoint\_sg\_ids               | Security groups used by interface endpoints                |
| interface\_endpoint\_private\_dns\_enabled | Private DNS enabled flag for interface endpoints           |

---

## License

MIT Licensed. See LICENSE for full details.

---

## Author

**Isreal Adenekan**