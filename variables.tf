variable "name" {
  type = string

  description = <<-EOT
  The name tag that will be applied to all resources in the VPC module including:
  - VPC
  - Subnets (public and private)
  - Internet Gateway
  - NAT Gateways
  - Route Tables
  - Security Groups
  This ensures consistent naming and easy resource identification.
  EOT
}

variable "cidr" {
  type = string

  description = <<-EOT
  The CIDR block for the VPC. This defines the IP address range for the entire VPC.
  Example: "10.0.0.0/16" for a VPC with 65,536 IP addresses.
  EOT
}

variable "azs" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of availability zones for creating subnets. If not specified, 
  the availability zones are fetched automatically using the available zones in the region.
  EOT
}

variable "public_subnet" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of CIDR blocks for public subnets. These subnets will have direct access to the internet
  through an Internet Gateway. Each subnet should be a subset of the VPC CIDR block.
  Example: ["10.0.1.0/24", "10.0.2.0/24"] for two public subnets.
  EOT
}

variable "private_subnet" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of CIDR blocks for private subnets. These subnets will have internet access through
  NAT Gateways but cannot be accessed directly from the internet. Each subnet should be a
  subset of the VPC CIDR block. Example: ["10.0.3.0/24", "10.0.4.0/24"] for two private subnets.
  EOT
}

variable "public_subnet_tags" {
  description = "Additional tags to apply to public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags to apply to private subnets"
  type        = map(string)
  default     = {}
}

variable "private_ip_map" {
  type    = bool
  default = false

  description = <<-EOT
  Whether to map public IP addresses on launch for private subnets. 
  If set to false, instances in the private subnets will not receive public IPs automatically.
  EOT
}

variable "instance_tenancy" {
  type    = string
  default = "default"

  description = <<-EOT
  The instance tenancy for the VPC. The default value is "default", which means instances run on shared hardware.
  If set to "dedicated", instances will run on dedicated hardware.
  EOT
}

variable "enable_dns_hostnames" {
  type    = bool
  default = false

  description = <<-EOT
  Whether to enable DNS hostnames for instances in the VPC. 
  When set to true, instances will be assigned a public DNS hostname.
  Default is false.
  EOT
}

variable "enable_dns_support" {
  type    = bool
  default = true

  description = <<-EOT
  Whether to enable DNS resolution in the VPC. When set to true, instances in the VPC can resolve domain names to IP addresses.
  Default is true.
  EOT
}

variable "tags" {
  type    = map(string)
  default = {}

  description = <<-EOT
  A map of tags to assign to resources created within the VPC. 
  The default is an empty map, meaning no tags are applied unless specified.
  You can provide key-value pairs for resources like the VPC, subnets, and security groups.
  EOT
}

variable "ingress" {
  type    = list(string)
  default = []

  description = <<-EOT
  List of allowed ingress (incoming) traffic types for the security group. 
  Valid options: "ssh", "http", "https". 
  This list determines which ports are open to the specified CIDR blocks for incoming traffic.
  If not specified, no ingress rules will be applied.
  EOT

  validation {
    condition = alltrue([
      for type in var.ingress : contains(["ssh", "http", "https", "kube"], type)
    ])
    error_message = <<-EOT
    One or more ingress types provided are invalid.
      Valid options: ssh, http, https.
    EOT
  }
}