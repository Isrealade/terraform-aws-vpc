##################################################################
# VPC
##################################################################
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC. Useful for referencing in other modules or resources."
}

output "availability_zones" {
  value       = length(var.azs) > 0 ? var.azs : local.azs
  description = "The availability zones used for subnet distribution."
}

##################################################################
# Public Subnets
##################################################################
output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "List of public subnet IDs with direct internet access."
}

output "public_subnet_map" {
  value       = { for idx, subnet in aws_subnet.public : idx => subnet.id }
  description = "Map of index to public subnet IDs for placement and HA."
}

##################################################################
# Private Subnets
##################################################################
output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "List of private subnet IDs. These subnets access the internet via NAT."
}

output "private_subnet_map" {
  value       = { for idx, subnet in aws_subnet.private : idx => subnet.id }
  description = "Map of index to private subnet IDs for placement and HA."
}

##################################################################
# NAT Gateway & EIPs
##################################################################
output "nat_gateway_public_ips" {
  value       = [for nat in aws_nat_gateway.nat : nat.public_ip]
  description = "List of public IPs of NAT Gateways used by private subnets."
}

output "nat_gateway_ids" {
  value       = [for nat in aws_nat_gateway.nat : nat.id]
  description = "List of NAT Gateway IDs."
}

output "nat_gateway_ips_map" {
  value       = { for idx, nat in aws_nat_gateway.nat : idx => nat.public_ip }
  description = "Indexed map of NAT Gateway public IPs."
}

output "elastic_ip_ids" {
  value       = [for eip in aws_eip.eip : eip.id]
  description = "List of Elastic IP IDs associated with NAT gateways."
}

##################################################################
# Internet Gateway
##################################################################
output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "The ID of the Internet Gateway."
}

##################################################################
# Route Tables
##################################################################
output "public_route_table_ids" {
  value       = { for az, rt in aws_route_table.public : az => rt.id }
  description = "Map of availability zone to public route table ID."
}

# output "public_subnet_route_table_map" {
#   value = {
#     for s in aws_subnet.public :
#     s.id => aws_route_table.public[s.availability_zone].id
#   }
#   description = "Map of public subnet ID to its route table ID."
# }


output "private_route_table_ids" {
  value       = { for az, rt in aws_route_table.private : az => rt.id }
  description = "Map of AZ to private route table IDs."
}

##################################################################
# NAT Gateway Subnets
##################################################################
output "nat_gateway_subnet_ids" {
  value       = [for nat in aws_nat_gateway.nat : nat.subnet_id]
  description = "List of subnets where NAT Gateways are deployed."
}

##################################################################
# Security Group
##################################################################
output "security_group_id" {
  value       = aws_security_group.security_group.id
  description = "The ID of the main security group for the VPC."
}

##################################################################
# DB Subnet Group
##################################################################
output "db_subnet_group_id" {
  value       = var.create_db_subnet ? aws_db_subnet_group.db_subnet[0].id : ""
  description = "The ID of the DB Subnet Group created. Empty if create_db_subnet is false."
}

output "db_subnet_group_subnet_ids" {
  value       = var.create_db_subnet ? aws_db_subnet_group.db_subnet[0].subnet_ids : []
  description = "The subnet IDs included in the DB Subnet Group. Empty if create_db_subnet is false."
}

##################################################################
# VPC Endpoints
##################################################################
## Gateway Endpoints
output "gateway_endpoint_ids" {
  value       = length(aws_vpc_endpoint.gateway) > 0 ? [for ep in aws_vpc_endpoint.gateway : ep.id] : []
  description = "IDs of the Gateway VPC Endpoints. Empty if none are created."
}

output "gateway_endpoint_services" {
  value       = length(aws_vpc_endpoint.gateway) > 0 ? [for ep in aws_vpc_endpoint.gateway : ep.service_name] : []
  description = "Service names of the Gateway VPC Endpoints."
}

## Interface Endpoints
output "interface_endpoint_ids" {
  value       = length(aws_vpc_endpoint.interface) > 0 ? { for idx, ep in aws_vpc_endpoint.interface : idx => ep.id } : {}
  description = "Map of keys to Interface VPC Endpoint IDs."
}

output "interface_endpoint_subnet_ids" {
  value       = length(aws_vpc_endpoint.interface) > 0 ? { for idx, ep in aws_vpc_endpoint.interface : idx => ep.subnet_ids } : {}
  description = "Map of keys to subnet IDs used by each Interface Endpoint."
}

output "interface_endpoint_sg_ids" {
  value       = length(aws_vpc_endpoint.interface) > 0 ? { for idx, ep in aws_vpc_endpoint.interface : idx => ep.security_group_ids } : {}
  description = "Map of keys to security group IDs attached to each Interface Endpoint."
}

output "interface_endpoint_private_dns_enabled" {
  value       = length(aws_vpc_endpoint.interface) > 0 ? { for idx, ep in aws_vpc_endpoint.interface : idx => ep.private_dns_enabled } : {}
  description = "Map of keys to private DNS enabled status for each Interface Endpoint."
}
