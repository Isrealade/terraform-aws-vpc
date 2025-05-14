# AWS VPC Terraform Module

This Terraform module creates a complete VPC infrastructure on AWS with public and private subnets, NAT Gateways, Internet Gateway, route tables, and security groups.

## Features

- Create a VPC with configurable CIDR block
- Create public and private subnets across multiple Availability Zones
- Create Internet Gateway for public subnets
- Create NAT Gateways for private subnets
- Create and configure route tables for public and private subnets
- Create security groups with configurable ingress rules
- Support for custom tags on all resources

## Usage

### Simple Example

```hcl
module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "1.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet = ["10.0.3.0/24", "10.0.4.0/24"]
  
  ingress = ["ssh", "http", "https"]
}
```

### Complete Example

```hcl
module "vpc" {
  source  = "Isrealade/vpc/aws"
  version = "1.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  
  private_ip_map = false
  
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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all resources as identifier | `string` | n/a | yes |
| cidr | CIDR block for the VPC | `string` | n/a | yes |
| azs | List of availability zones | `list(string)` | `[]` | no |
| public_subnet | List of CIDR blocks for public subnets | `list(string)` | `[]` | no |
| private_subnet | List of CIDR blocks for private subnets | `list(string)` | `[]` | no |
| private_ip_map | Whether to map public IP on launch for private subnets | `bool` | `false` | no |
| instance_tenancy | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| enable_dns_support | Whether to enable DNS support in the VPC | `bool` | `true` | no |
| enable_dns_hostnames | Whether to enable DNS hostnames in the VPC | `bool` | `true` | no |
| ingress | List of ingress rules to apply (ssh, http, https) | `list(string)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| public_subnet_ids | List of IDs of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| nat_gateway_ids | List of NAT Gateway IDs |
| security_group_id | The ID of the security group |

## License

MIT Licensed. See LICENSE for full details.

## Author

Isreal Adenekan

## Additional Information

For more detailed examples, please check the `examples` directory in this repository. 
