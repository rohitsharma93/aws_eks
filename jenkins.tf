# jenkins Security Group  
resource "aws_security_group" "jenkins" {
  count       = local.environments[terraform.workspace].jenkins.enabled == "true" ? 1 : 0
  name        = "${local.environment}-jenkins-${local.project_name}"
  description = "Allow jenkins inbound traffic"
  vpc_id      = contains(["dev", "stage"], terraform.workspace) ? data.aws_vpcs.default.ids[0] : module.vpc[0].vpc_id

  ingress {
    from_port   = 8080 #  jenkins port for vpc
    to_port     = 8080
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

  ingress {
    from_port   = 8080 # jenkins default port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.antiers_ip
    description = "Antier IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# get Random subnet
resource "random_shuffle" "jenkins" {
  count        = local.environments[terraform.workspace].jenkins.enabled == "true" ? 1 : 0
  input        = contains(["dev", "stage"], terraform.workspace) ? data.aws_subnets.default.ids : module.vpc[0].public_subnets
  result_count = 1
}

# Create jenkins Instance
resource "aws_instance" "jenkins" {
  count                  = local.environments[terraform.workspace].jenkins.enabled == "true" ? 1 : 0
  ami                    = data.aws_ami.ubuntu-20.id
  instance_type          = local.environments[terraform.workspace].jenkins.instance_type
  subnet_id              = random_shuffle.jenkins[0].result[0]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  user_data              = file("scripts/install_jenkins.sh")
  vpc_security_group_ids = [aws_security_group.jenkins[0].id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }
  tags = {
    Name = "${local.environment}-jenkins-${local.project_name}"
  }
}


# jenkins Elastic IP
resource "aws_eip" "jenkins" {
  count    = local.environments[terraform.workspace].jenkins.enabled == "true" ? 1 : 0
  instance = aws_instance.jenkins[0].id
  tags = {
    Name = "${local.environment}-jenkins-${local.project_name}"
  }
}