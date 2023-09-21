data "aws_availability_zones" "available" {}

locals {
  name   = "ex-${basename(path.cwd)}"
  region = var.region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Example = local.name
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name             = "${var.env_prefix_code}-vpc"
  cidr             = var.vpc_cidr
  instance_tenancy = "default"

  azs             = var.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  single_nat_gateway                    = true
  enable_nat_gateway                    = true
  enable_dns_support                    = true
  enable_dns_hostnames                  = true
  create_igw                            = true
  map_public_ip_on_launch               = true
  create_elasticache_subnet_route_table = true

  customer_gateway_tags = {
    Name = "${var.env_prefix_code}-igw"
  }

  public_subnet_tags = {
    Name                                = "${var.env_prefix_code}-public"
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/elb"            = 1
  }

  private_subnet_tags = {
    Name                                = "${var.env_prefix_code}-private"
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"   = 1
  }

  tags = {
    Name = "${var.env_prefix_code}-vpc}"
  }
}
