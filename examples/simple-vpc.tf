provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../.."

  name = "simple-vpc"
  cidr = "10.0.0.0/16"

  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet = ["10.0.3.0/24", "10.0.4.0/24"]

  ingress = ["ssh", "http", "https"]
} 