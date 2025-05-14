   provider "aws" {
     region = "us-east-1"
   }

   module "vpc" {
     source = "Isrealade/vpc/aws"

     name = "example-vpc"
     cidr = "10.0.0.0/16"

     azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

     public_subnet  = ["10.0.1.0/24", "10.0.2.0/24"]
     private_subnet = ["10.0.3.0/24", "10.0.4.0/24"]

     instance_tenancy     = "default"
     enable_dns_support   = true
     enable_dns_hostnames = true

     ingress = ["ssh", "http", "https"]

     tags = {
       Environment = "development"
       Project     = "vpc-example"
     }
   }