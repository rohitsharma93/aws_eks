# Get ubuntu20 ami id
data "aws_ami" "ubuntu-20" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230328"]
  }
}
# get AZ's for region
data "aws_availability_zones" "available" {
  state = "available"
}

# get default VPC ID
data "aws_vpcs" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

# get default VPC details
data "aws_vpc" "default" {
  id = data.aws_vpcs.default.ids[0]
}

# get default subnet ID
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.default.ids
  }
}

# fetch buildspec files details
data "local_file" "buildspec_local" {
  filename = "scripts/buildspec.yaml"
}

#add password in rabbitmq user data script
data "template_file" "rabbitmq" {
  count    = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  template = file("templates/install_rmq_docker.sh.tpl")
  vars = {
    password = random_password.rabbitmq[0].result
  }
}

# add cluster name in alb template
data "template_file" "alb" {
  template = file("templates/alb.yaml.tpl")
  vars = {
    cluster_name = module.eks.cluster_name
  }
}

# add loki bucket and region in template
data "template_file" "loki" {
  template = file("templates/loki.yaml.tpl")
  vars = {
    aws_region  = local.environments[terraform.workspace].region
    loki_bucket = aws_s3_bucket.loki.id
  }
}

