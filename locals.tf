data "aws_availability_zones" "available" {
  state = "available"
}

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
  }

}