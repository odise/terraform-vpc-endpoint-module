resource "random_string" "this" {
  length  = 6
  upper   = false
  special = false
  number  = false
}


data "aws_availability_zones" "available" {
  state = "available"
}


module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.23.0"

  name                 = "${local.name_prefix}-${random_string.this.result}"
  cidr                 = local.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  intra_subnets        = local.subnet_masks
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false
  single_nat_gateway   = false

  intra_subnet_tags = {
    Tier = "Intra"
  }
  default_network_acl_name    = "${local.name_prefix}-default"
  intra_dedicated_network_acl = true
}

module "this" {
  source                   = "../../"
  aws_region               = "eu-central-1"
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  #   enable_dynamodb_endpoint = false
  network_acl_ids = [module.vpc.intra_network_acl_id, module.vpc.default_network_acl_id]
  route_table_ids = concat(module.vpc.intra_route_table_ids, list(module.vpc.default_route_table_id))
  #   subnets        = module.vpc.intra_subnets
  vpc_id = module.vpc.vpc_id
}
