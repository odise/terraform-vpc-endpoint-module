# VPC Endpoint for S3
data "aws_vpc_endpoint_service" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  service = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = data.aws_vpc_endpoint_service.s3[0].service_name
  tags         = var.tags
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  count = var.enable_s3_endpoint && length(var.route_table_ids) > 0 ? length(var.route_table_ids) : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = var.route_table_ids[count.index]
}

# VPC Endpoint for DynamoDB
data "aws_vpc_endpoint_service" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  service = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = var.vpc_id
  service_name = data.aws_vpc_endpoint_service.dynamodb[0].service_name
  tags         = var.tags
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  count = var.enable_dynamodb_endpoint && length(var.route_table_ids) > 0 ? length(var.route_table_ids) : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = var.route_table_ids[count.index]
}

# S3 routes to the endpoint
data "external" "cidr_list" {
  program = ["bash", "${path.module}/cidr_list.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    region      = var.aws_region
    aws_service = "s3"
  }
}

# DynamoDB routes to the endpoint
data "external" "cidr_list_dynamodb" {
  program = ["bash", "${path.module}/cidr_list.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    region      = var.aws_region
    aws_service = "dynamodb"
  }
}

locals {
  s3_list       = split("\t", data.external.cidr_list.result["cidr_list"])
  dynamodb_list = split("\t", data.external.cidr_list_dynamodb.result["cidr_list"])
}

# open ports to communicate with the VPC S3 endpoint
# for more details have a look at https://aws.amazon.com/premiumsupport/knowledge-center/connect-s3-vpc-endpoint/
resource "aws_network_acl_rule" "inbound_s3" {
  count = var.enable_s3_endpoint ? length(local.s3_list) * length(var.network_acl_ids) : 0

  network_acl_id = element(var.network_acl_ids, floor(count.index / length(local.s3_list)))

  from_port   = 0
  to_port     = 0
  rule_action = "allow"
  protocol    = "-1"

  cidr_block  = element(local.s3_list, count.index)
  egress      = false
  rule_number = var.s3_nacl_rule_number + var.multiplicator * count.index
}

resource "aws_network_acl_rule" "outbound_s3" {
  count = var.enable_s3_endpoint ? length(local.s3_list) * length(var.network_acl_ids) : 0

  network_acl_id = element(var.network_acl_ids, floor(count.index / length(local.s3_list)))

  from_port   = 0
  to_port     = 0
  rule_action = "allow"
  protocol    = "-1"
  cidr_block  = element(local.s3_list, count.index)
  egress      = true
  rule_number = var.s3_nacl_rule_number + var.multiplicator * count.index
}

resource "aws_network_acl_rule" "inbound_dynamodb" {
  count = var.enable_dynamodb_endpoint ? length(local.dynamodb_list) * length(var.network_acl_ids) : 0

  network_acl_id = element(var.network_acl_ids, floor(count.index / length(local.dynamodb_list)))

  from_port   = 0
  to_port     = 0
  rule_action = "allow"
  protocol    = "-1"
  cidr_block  = element(local.dynamodb_list, count.index)
  egress      = false
  rule_number = var.dynamodb_nacl_rule_number + var.multiplicator * count.index
}

resource "aws_network_acl_rule" "outbound_dynamodb" {
  count = var.enable_dynamodb_endpoint ? length(local.dynamodb_list) * length(var.network_acl_ids) : 0

  network_acl_id = element(var.network_acl_ids, floor(count.index / length(local.dynamodb_list)))

  from_port   = 0
  to_port     = 0
  rule_action = "allow"
  protocol    = "-1"
  cidr_block  = element(local.dynamodb_list, count.index)
  egress      = true
  rule_number = var.dynamodb_nacl_rule_number + var.multiplicator * count.index
}
