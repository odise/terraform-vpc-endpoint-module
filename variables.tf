variable enable_s3_endpoint {
  type = bool
}
variable enable_dynamodb_endpoint {
  type = bool
}
variable network_acl_ids {
  default = []
}
variable route_table_ids {
  default = []
}
# variable subnets {}
variable vpc_id {}
variable aws_region {}
variable s3_nacl_rule_number { default = 1000 }
variable dynamodb_nacl_rule_number { default = 1100 }
variable multiplicator { default = 1 }

variable tags {
  default = {}
}
