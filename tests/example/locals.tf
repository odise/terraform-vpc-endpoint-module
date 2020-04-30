locals {
  name_prefix  = "vpcendpoints"
  vpc_cidr     = "172.16.8.0/21"
  subnet_masks = ["172.16.8.0/23", "172.16.10.0/23", "172.16.12.0/23"]
}
