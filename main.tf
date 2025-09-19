##################################################################
############# VPC  
##################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { "Name" = var.name })

}

##################################################################
############# Public Subnet
##################################################################

resource "aws_subnet" "public" {
  for_each                = local.public_subnet_defs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, var.public_subnet_tags, {
    Name = "${var.name}-public-${each.value.index}"
  })
}

##################################################################
############# Private Subnet
##################################################################

resource "aws_subnet" "private" {
  for_each                = local.private_subnet_defs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.private_ip_map

  tags = merge(var.tags, var.private_subnet_tags, {
    Name = "${var.name}-private-${each.value.index}"
  })
}


##################################################################
############# DB Subnet Group
##################################################################

resource "aws_db_subnet_group" "db_subnet" {
  count      = var.create_db_subnet ? 1 : 0
  name       = var.subnet_group_name
  subnet_ids = values(aws_subnet.private)[*].id

  tags = merge(var.tags, var.db_subnet_group_tags, {
    Name = "${var.name}-db_subnet_group-${count.index}"
  })
}

##################################################################
############# Internet Gateway
##################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

##################################################################
############# Elastic IP
##################################################################

resource "aws_eip" "eip" {
  count      = local.nat_count
  depends_on = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "${var.name}-eip-${count.index}" })
}

##################################################################
############# NAT Gateway 
##################################################################

resource "aws_nat_gateway" "nat" {
  count         = local.nat_count
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = local.nat_public_subnet_ids[count.index]
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })
}

##################################################################
############# Route Table
##################################################################

## PUBLIC ROUTE TABLE AND ROUTE 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

## PRIVATE ROUTE TABLE AND ROUTE 
resource "aws_route_table" "private" {
  for_each = toset(local.azs_with_private)
  vpc_id   = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat && local.nat_count > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.one_nat_per_az ? local.nat_by_az[each.key] : aws_nat_gateway.nat[0].id
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt-${each.key}" })
}


##################################################################
############# Route Table association
##################################################################

## PUBLIC ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}


## PRIVATE ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = local.private_rts_map[each.value.availability_zone]
}

##################################################################
############# Security Group
##################################################################

resource "aws_security_group" "security_group" {
  name   = "${var.name}-sg"
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = var.name })
}


## INGRESS RULE
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each          = { for type in var.ingress : type => local.ingress_options[type] }
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  ip_protocol       = each.value.ip_protocol
  to_port           = each.value.to_port
}

## CUSTOM INGRESS RULE
resource "aws_vpc_security_group_ingress_rule" "custom" {
  for_each          = { for idx, rule in var.custom_ingress : idx => rule }
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
}

## EGRESS RULE
resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


##################################################################
############# VPC Endpoint
##################################################################

### GATEWAY ENDPOINT
resource "aws_vpc_endpoint" "gateway" {
  count = var.create_endpoint ? length(var.vpc_endpoints.gateway) : 0

  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${local.region}.${var.vpc_endpoints.gateway[count.index].service_name}"
  route_table_ids   = values(aws_route_table.private)[*].id

  policy = lookup(var.vpc_endpoints.gateway[count.index], "policy", jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  }))

  tags = merge(
    var.tags,
    var.gateway_endpoints_default_tags,
    lookup(var.vpc_endpoints.gateway[count.index], "tags", {}),
    {
      Name = "${var.name}-gateway-${var.vpc_endpoints.gateway[count.index].service_name}"
    }
  )
}

### INTERFACE ENDPOINT
resource "aws_vpc_endpoint" "interface" {
  for_each = var.create_endpoint ? { for idx, ep in var.vpc_endpoints.interface : idx => ep } : {}

  vpc_id              = aws_vpc.main.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${local.region}.${each.value.service_name}"
  subnet_ids          = length(each.value.subnet_ids) > 0 ? each.value.subnet_ids : local.interface_subnets
  security_group_ids  = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : [aws_security_group.security_group.id]
  private_dns_enabled = each.value.private_dns_enabled

  policy = lookup(each.value, "policy", jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
    }]
  }))

  tags = merge(
    var.tags,
    var.interface_endpoints_default_tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${var.name}-interface_endpoint-${each.key}"
    }
  )
}