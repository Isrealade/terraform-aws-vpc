output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC. This can be used to reference the VPC in other resources or modules."
}

output "availability_zones" {
  value       = length(var.azs) > 0 ? var.azs : local.azs
  description = "The availability zones used for subnet distribution. If no AZs were specified in the input variables, this will return the automatically selected AZs from the region."
}

# Public Subnets
output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "List of public subnet IDs. These subnets have direct internet access through the Internet Gateway and can be used for resources that need to be publicly accessible."
}

output "public_subnet_map" {
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
  description = "Map of availability zones to public subnet IDs. Useful for placing resources in specific AZs while maintaining high availability."
}

# Private Subnets
output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "List of private subnet IDs. These subnets have internet access through NAT Gateways and are suitable for resources that should not be directly accessible from the internet."
}

output "private_subnet_map" {
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
  description = "Map of availability zones to private subnet IDs. Useful for placing resources in specific AZs while maintaining high availability and security."
}

# NAT Gateway Outputs
output "nat_gateway_public_ips" {
  value       = [for nat in aws_nat_gateway.nat : nat.public_ip]
  description = "List of public IPs of the NAT Gateways. These IPs are used by resources in private subnets to access the internet."
}

output "nat_gateway_ips_map" {
  value       = { for idx, nat in aws_nat_gateway.nat : idx => nat.public_ip }
  description = "Indexed map of NAT Gateway public IPs. Useful for associating specific NAT Gateways with their corresponding private subnets."
}

# Elastic IPs
output "elastic_ip_ids" {
  value       = [for eip in aws_eip.eip : eip.id]
  description = "List of Elastic IP IDs associated with NAT gateways. These EIPs are used to provide static public IPs for the NAT Gateways."
}

# Security Group
output "security_group_id" {
  value       = aws_security_group.security_group.id
  description = "The ID of the security group created. This security group can be used to control inbound and outbound traffic for resources in the VPC."
}
