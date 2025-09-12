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
  count                   = length(var.public_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}

##################################################################
############# Private Subnet
##################################################################

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.private_ip_map

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}

##################################################################
############# Internet Gateway
##################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = var.name })
}

##################################################################
############# Elastic IP
##################################################################

resource "aws_eip" "eip" {
  count      = length(var.private_subnet)
  depends_on = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}

##################################################################
############# NAT Gateway 
##################################################################

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}

##################################################################
############# Route Table
##################################################################

## PUBLIC ROUTE TABLE AND ROUTE 
resource "aws_route_table" "public" {
  count  = length(var.public_subnet)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}


## PRIVATE ROUTE TABLE AND ROUTE 
resource "aws_route_table" "private" {
  count  = length(var.private_subnet)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(var.tags, { Name = "${var.name}-${count.index}" })
}

##################################################################
############# Route Table association
##################################################################

## PUBLIC ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}


## PRIVATE ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
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


## EGRESS RULE
resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
