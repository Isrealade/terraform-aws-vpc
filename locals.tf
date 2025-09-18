data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  ### LOCAL DEFINITION FOR AZ 
  azs = length(var.azs) > 0 ? var.azs : data.aws_availability_zones.available.names

  ### INGRESS OPTIONS FOR SECURITY GROUP ###
  ingress_options = {
    ssh = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
    }

    http = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
    }

    https = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
    }

    kube = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 6443
      to_port     = 6443
      ip_protocol = "tcp"
    }

    postgresql = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 5432
      to_port     = 5432
      ip_protocol = "tcp"
    }

    "mysql/aurora" = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 3306
      to_port     = 3306
      ip_protocol = "tcp"
    }

    mssql = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 1433
      to_port     = 1433
      ip_protocol = "tcp"
    }

    oracle-rds = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 1521
      to_port     = 1521
      ip_protocol = "tcp"
    }

    redshift = {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 5439
      to_port     = 5439
      ip_protocol = "tcp"
    }
  }

  region = var.region != "" ? var.region : data.aws_region.current.id

  nat_by_az = { for i, az in local.azs : az => aws_nat_gateway.nat[i].id }

  private_rts = { for az, rt in aws_route_table.private : az => rt.id }

  public_rts_map  = { for i, az in local.azs : az => aws_route_table.public[i].id }
  private_rts_map = { for i, az in local.azs : az => aws_route_table.private[i].id }

  # Map of AZ -> list of public subnet IDs
  public_subnets_by_az = {
    for az in local.azs :
    az => [for s in aws_subnet.public : s.id if s.availability_zone == az]
  }

  # Only create RTs for AZs that actually have subnets
  public_rts = {
    for az, subnets in local.public_subnets_by_az :
    az => az # placeholder, will map to aws_route_table.public later
    if length(subnets) > 0
  }

  private_offset = length(var.public_subnet) > 0 ? length(var.public_subnet) : var.public_subnet_count

  # Group private subnets by AZ
  private_subnets_by_az = {
    for az in local.azs :
    az => [for s in aws_subnet.private : s.id if s.availability_zone == az]
  }

  # Pick first subnet in each AZ (one per AZ for interface endpoints)
  interface_subnets = flatten([
    for az, subnets in local.private_subnets_by_az :
    subnets[0] # pick the first subnet in this AZ
  ])

   # Total subnets (public + private)
  public_subnet_cidrs = length(var.public_subnet) > 0 ? var.public_subnet : [
    for i in range(var.public_subnet_count) : cidrsubnet(var.cidr, var.subnet_newbits, i)
  ]

  private_subnet_cidrs = length(var.private_subnet) > 0 ? var.private_subnet : [
    for i in range(var.private_subnet_count) : cidrsubnet(var.cidr, var.subnet_newbits, i + local.private_offset)
  ]

}
