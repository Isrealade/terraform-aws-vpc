variable "name" {
  type = string

  description = <<-EOT
  The name tag that will be applied to all resources in the VPC module, including:
  - VPC
  - Subnets (public and private)
  - Internet Gateway
  - NAT Gateways
  - Route Tables
  - Security Groups
  This ensures consistent naming and easy resource identification.
  EOT
}

variable "region" {
  type    = string
  default = ""

  description = <<-EOT
  The AWS region to deploy the VPC to. 
  If left empty, Terraform will use the provider's configured region.
  EOT
}

variable "cidr" {
  type = string

  description = <<-EOT
  The CIDR block for the VPC. Defines the IP address range for the VPC.
  Example: "10.0.0.0/16" for a VPC with 65,536 IP addresses.
  EOT
}

variable "azs" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of availability zones for creating subnets. 
  If not specified, Terraform automatically fetches available AZs in the region.
  EOT
}

variable "public_subnet" {
  type    = list(string)
  default = []
  validation {
    condition     = !(length(var.public_subnet) > 0 && var.public_subnet_count > 0)
    error_message = "Provide either public_subnet OR public_subnet_count, not both."
  }

  description = <<-EOT
  List of CIDR blocks for public subnets. These subnets have direct Internet access.
  Each subnet must be a subset of the VPC CIDR block.
  Example: ["10.0.1.0/24", "10.0.2.0/24"] for two public subnets.
  EOT
}

variable "public_subnet_count" {
  type    = number
  default = 0

  description = <<-EOT
  The number of public subnets to auto-generate if `public_subnet` is not provided.
  EOT
}

variable "private_subnet" {
  type    = list(string)
  default = []
  validation {
    condition     = !(length(var.private_subnet) > 0 && var.private_subnet_count > 0)
    error_message = "Provide either private_subnet OR private_subnet_count, not both."
  }

  description = <<-EOT
  List of CIDR blocks for private subnets. Private subnets have Internet access through NAT Gateways
  but are not directly accessible from the Internet.
  Example: ["10.0.3.0/24", "10.0.4.0/24"] for two private subnets.
  EOT
}

variable "private_subnet_count" {
  type    = number
  default = 0

  description = <<-EOT
  The number of private subnets to auto-generate if `private_subnet` is not provided.
  At least one private subnet is required if you plan to create a DB subnet group.
  EOT
}

variable "private_subnet_offset" {
  type        = number
  default     = 64
  description = "Fixed offset for private subnets when auto-generating CIDRs: private i uses index i + private_subnet_offset. Keep constant after first deploy to avoid CIDR shifts."
}

variable "subnet_newbits" {
  type    = number
  default = 8

  description = <<-EOT
  The number of new bits to use with `cidrsubnet` when auto-generating subnets.
  Controls the subnet size.
  EOT
}

variable "create_db_subnet" {
  type    = bool
  default = false

  description = "Whether to create a DB Subnet Group using private subnets."
}

variable "subnet_group_name" {
  type    = string
  default = ""

  description = <<-EOT
  The name of the DB subnet group. If omitted, Terraform generates a random unique name.
  EOT
}

variable "public_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to public subnets."
}

variable "private_subnet_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to private subnets."
}

variable "db_subnet_group_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the DB subnet group."
}

variable "private_ip_map" {
  type    = bool
  default = false

  description = <<-EOT
  Whether instances in private subnets receive public IPs automatically.
  Typically false for private subnets.
  EOT
}

variable "instance_tenancy" {
  type    = string
  default = "default"

  description = <<-EOT
  The instance tenancy for the VPC. Options:
  - "default": instances run on shared hardware.
  - "dedicated": instances run on dedicated hardware.
  EOT
}

variable "enable_dns_hostnames" {
  type    = bool
  default = false

  description = <<-EOT
  Whether instances in the VPC receive public DNS hostnames.
  Must be true for some AWS services like EC2 to have public DNS names.
  EOT
}

variable "enable_dns_support" {
  type    = bool
  default = true

  description = <<-EOT
  Whether DNS resolution is enabled in the VPC.
  Required for instances to resolve domain names.
  EOT
}

variable "ingress" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of allowed ingress traffic types for the default security group.
  Valid options are the keys of `local.ingress_options`.
  If empty, no default ingress rules are applied.
  EOT

  validation {
    condition     = alltrue([for type in var.ingress : contains(keys(local.ingress_options), type)])
    error_message = "One or more ingress types provided are invalid. Valid options: ${join(", ", keys(local.ingress_options))}"
  }
}

variable "custom_ingress" {
  type = list(object({
    cidr_ipv4   = string
    from_port   = number
    to_port     = number
    ip_protocol = string
  }))
  default = []

  description = <<-EOT
  List of custom ingress rules for the security group.
  Each item must include:
    - cidr_ipv4
    - from_port
    - to_port
    - ip_protocol
  Example:
    [
      {
        cidr_ipv4 = "1.2.3.4/32"
        from_port = 1234
        to_port = 1234
        ip_protocol = "tcp"
      }
    ]
  EOT
}

variable "create_endpoint" {
  type        = bool
  default     = false
  description = "Whether to create VPC endpoints (Gateway or Interface)."
}

variable "vpc_endpoints" {
  type = object({
    # Gateway endpoints for a LIST of objects
    gateway = optional(list(object({
      service_name = string
      policy       = optional(string, "")
      tags         = optional(map(string), {})
    })), [])

    # Interface endpoints for a LIST of objects
    interface = optional(list(object({
      service_name        = string
      subnet_ids          = optional(list(string), [])
      security_group_ids  = optional(list(string), [])
      private_dns_enabled = bool
      policy              = optional(string, "")
      tags                = optional(map(string), {})
    })), [])
  })

  default = {
    gateway   = []
    interface = []
  }

  description = <<-EOT
  Configuration for creating AWS VPC endpoints inside the module.

  **gateway** (list, optional):
    - Create one or more Gateway endpoints (e.g., S3, DynamoDB).
    - Each object supports:
        * service_name     – Required. AWS service (e.g., "s3", "dynamodb").
        * ip_address_type  – Optional. "ipv4" (default) or "dualstack".
        * policy           – Optional. JSON policy for fine-grained access.
    - Defaults to an empty list (no gateway endpoints).

  **interface** (list, optional):
    - Create one or more Interface endpoints.
    - Each object supports:
        * service_name        – Required. AWS service (e.g., "ec2", "ssm").
        * subnet_ids          – Optional. List of subnet IDs. Empty = module private subnets.
        * security_group_ids  – Optional. List of SG IDs. Empty = module default SG.
        * private_dns_enabled – Required. Boolean to enable private DNS.
        * policy              – Optional. JSON policy.
    - Defaults to an empty list (no interface endpoints).
  EOT

  validation {
    condition = alltrue([
      for g in var.vpc_endpoints.gateway : length(trimspace(g.service_name)) > 0
      ]) && alltrue([
      for i in var.vpc_endpoints.interface : length(trimspace(i.service_name)) > 0
    ])
    error_message = <<-EOT
  Validation failed for vpc_endpoints:
  - Each gateway endpoint must include a non-empty service_name.
  - Each interface endpoint must include a non-empty service_name.
  EOT
  }

}


variable "enable_nat" {
  type        = bool
  default     = true
  description = "Turn NAT Gateways on/off. If there are no private subnets, no NATs are created."
}

variable "single_nat" {
  type        = bool
  default     = true
  description = "When enable_nat=true, create a single NAT Gateway for all private subnets."

  validation {
    condition     = (!var.enable_nat) || (var.single_nat != var.one_nat_per_az)
    error_message = "With enable_nat=true, set exactly one of single_nat or one_nat_per_az to true."
  }
}

variable "one_nat_per_az" {
  type        = bool
  default     = false
  description = "When enable_nat=true, create one NAT Gateway per availability zone."
}


variable "gateway_endpoints_default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags applied to all Gateway endpoints. Per-endpoint tags override on key conflicts."
}

variable "interface_endpoints_default_tags" {
  type        = map(string)
  default     = {}
  description = "Default tags applied to all Interface endpoints. Per-endpoint tags override on key conflicts."
}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "Default tags applied to all resources in the VPC module."
}