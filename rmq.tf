# rabbitmq Security Group
resource "aws_security_group" "rabbitmq" {
  count       = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  name        = "${local.environment}-rabbitmq-${local.project_name}"
  description = "Allow rabbitmq inbound traffic"
  vpc_id      = contains(["dev", "stage"], terraform.workspace) ? data.aws_vpcs.default.ids[0] : module.vpc[0].vpc_id

  ingress {
    from_port   = 5672 # rabbitmq default port
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = var.antiers_ip
    description = "Antier IP"
  }
  ingress {
    from_port   = 15672 # rabbitmq default port
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = var.antiers_ip
    description = "Antier IP"
  }
  ingress {
    from_port   = 5672 # rabbitmq default port
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [contains(["dev", "stage"], terraform.workspace) ? data.aws_vpc.default.cidr_block : local.environments[terraform.workspace].vpc_cidr_block]
    description = "VPC CIDR"
  }
  ingress {
    from_port   = 15672 # rabbitmq default port
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [contains(["dev", "stage"], terraform.workspace) ? data.aws_vpc.default.cidr_block : local.environments[terraform.workspace].vpc_cidr_block]
    description = "VPC CIDR"
  }
  ingress {
    from_port   = 9100 # node-exporter default port
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [contains(["dev", "stage"], terraform.workspace) ? data.aws_vpc.default.cidr_block : local.environments[terraform.workspace].vpc_cidr_block]
    description = "Node Exporter"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# get Random subnet
resource "random_shuffle" "rabbitmq" {
  count        = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  input        = contains(["dev", "stage"], terraform.workspace) ? data.aws_subnets.default.ids : module.vpc[0].public_subnets
  result_count = 1
}

# Create rabbitmq Instance
resource "aws_instance" "rabbitmq" {
  count                  = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  ami                    = data.aws_ami.ubuntu-20.id
  instance_type          = local.environments[terraform.workspace].rabbitmq.instance_type
  subnet_id              = random_shuffle.rabbitmq[0].result[0]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  user_data              = data.template_file.rabbitmq[0].rendered
  vpc_security_group_ids = [aws_security_group.rabbitmq[0].id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
  tags = {
    Name = "${local.environment}-rabbitmq-${local.project_name}"
  }
}

# rabbitmq Elastic IP
resource "aws_eip" "rabbitmq" {
  count    = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  instance = aws_instance.rabbitmq[0].id
  tags = {
    Name = "${local.environment}-rabbitmq-${local.project_name}"
  }
}

#generate random password for rabbitmq
resource "random_password" "rabbitmq" {
  count   = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  length  = 16
  special = false
}

# store password in paramter store
resource "aws_ssm_parameter" "rabbitmq" {
  count = local.environments[terraform.workspace].rabbitmq.enabled == "true" ? 1 : 0
  name  = "/${terraform.workspace}/rabbitmq/password"
  type  = "SecureString"
  value = random_password.rabbitmq[0].result
}

