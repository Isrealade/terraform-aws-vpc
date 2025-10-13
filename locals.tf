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

  # NAT strategy computations
  num_azs             = length(local.azs)
  num_private_subnets = length(aws_subnet.private)

  # Number of NAT gateways to create
  nat_count = (var.enable_nat && local.num_private_subnets > 0) ? (var.one_nat_per_az ? local.num_azs : 1) : 0

  # Safe mapping of NAT by AZ only when per-AZ strategy is enabled
  nat_by_az = var.one_nat_per_az && local.nat_count > 0 ? { for i, az in local.azs : az => aws_nat_gateway.nat[i].id } : {}

  # Route table map for private (public uses a single RT)
  private_rts_map = { for az, rt in aws_route_table.private : az => rt.id }

  # Deterministic ordering helpers for subnets (when using for_each)
  public_subnet_keys_sorted  = sort(keys(aws_subnet.public))
  private_subnet_keys_sorted = sort(keys(aws_subnet.private))

  public_subnets_ordered  = [for k in local.public_subnet_keys_sorted : aws_subnet.public[k]]
  private_subnets_ordered = [for k in local.private_subnet_keys_sorted : aws_subnet.private[k]]

  # Map of AZ -> ordered list of public/private subnet IDs
  public_subnet_ids_by_az = {
    for az in local.azs :
    az => [for s in local.public_subnets_ordered : s.id if s.availability_zone == az]
  }

  private_subnet_ids_by_az = {
    for az in local.azs :
    az => [for s in local.private_subnets_ordered : s.id if s.availability_zone == az]
  }

  # AZs that actually have subnets
  azs_with_public  = [for az in local.azs : az if length(local.public_subnet_ids_by_az[az]) > 0]
  azs_with_private = [for az in local.azs : az if length(local.private_subnet_ids_by_az[az]) > 0]

  # Choose public subnets where NATs will live
  nat_public_subnet_ids = local.nat_count == 0 ? [] : (
    var.one_nat_per_az
    ? [for az in local.azs : local.public_subnet_ids_by_az[az][0]]
    : [local.public_subnets_ordered[0].id]
  )

  # (old public_rts helper removed)

  # Fixed offset to prevent CIDR shifts when public count changes
  private_offset = var.private_subnet_offset

  # Group private subnets by AZ
  private_subnets_by_az = {
    for az in local.azs :
    az => [for s in aws_subnet.private : s.id if s.availability_zone == az]
  }

  # Pick first private subnet ID in each AZ that has private subnets (for interface endpoints)
  interface_subnets = [for az in local.azs_with_private : local.private_subnet_ids_by_az[az][0]]

  # Total subnets (public + private)
  public_subnet_cidrs = length(var.public_subnet) > 0 ? var.public_subnet : [
    for i in range(var.public_subnet_count) : cidrsubnet(var.cidr, var.subnet_newbits, i)
  ]

  private_subnet_cidrs = length(var.private_subnet) > 0 ? var.private_subnet : [
    for i in range(var.private_subnet_count) : cidrsubnet(var.cidr, var.subnet_newbits, i + local.private_offset)
  ]

  # Subnet definition maps with stable, sortable keys
  public_subnet_defs = {
    for i, cidr in local.public_subnet_cidrs :
    format("%03d-%s", i, local.azs[i % length(local.azs)]) => {
      cidr  = cidr
      az    = local.azs[i % length(local.azs)]
      index = i
    }
  }

  private_subnet_defs = {
    for i, cidr in local.private_subnet_cidrs :
    format("%03d-%s", i, local.azs[i % length(local.azs)]) => {
      cidr  = cidr
      az    = local.azs[i % length(local.azs)]
      index = i
    }
  }

  traffic_type    = ["ACCEPT", "REJECT", "ALL"]
  log_group_class = ["STANDARD", "INFREQUENT_ACCESS", "DELIVERY"]
}