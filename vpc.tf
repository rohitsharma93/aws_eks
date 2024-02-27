# Creating VPC for creating all resources in a private virtual env
module "vpc" {
  count  = contains(["dev", "stage"], terraform.workspace) ? 0 : 1
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.environment}-vpc-${local.project_name}"
  cidr = local.environments[terraform.workspace].vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnet_ids
  public_subnets  = local.public_subnet_ids

  enable_nat_gateway = true
  enable_vpn_gateway = true
}
