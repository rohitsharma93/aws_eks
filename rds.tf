# Custom mysql Paramter Group
resource "aws_db_parameter_group" "mysql" {
  count  = local.environments[terraform.workspace].rds.database == "mysql" ? 1 : 0
  name   = "${terraform.workspace}-mysql-${local.project_name}"
  family = "mysql${regex("^(.*)\\..*$", local.environments[terraform.workspace].rds.version)[0]}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  parameter {
    name  = "interactive_timeout"
    value = "60"
  }
  parameter {
    name  = "wait_timeout"
    value = "60"
  }
  parameter {
    name  = "general_log"
    value = "0"
  }
  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
}

# Custom postgres Paramter Group
resource "aws_db_parameter_group" "postgres" {
  count  = local.environments[terraform.workspace].rds.database == "postgres" ? 1 : 0
  name   = "${terraform.workspace}-postgres-${local.project_name}"
  family = "postgres${regex("^(.*)\\..*$", local.environments[terraform.workspace].rds.version)[0]}"

  parameter {
    name  = "log_min_duration_statement"
    value = "5000"
  }
}

#rds security groups
resource "aws_security_group" "rds" {
  name   = "${terraform.workspace}-rds-${local.project_name}"
  vpc_id = contains(["dev", "stage"], terraform.workspace) ? data.aws_vpcs.default.ids[0] : module.vpc[0].vpc_id
  ingress {
    description = "VPC Cidr"
    from_port   = local.environments[terraform.workspace].rds.database == "mysql" ? 3306 : 5432
    to_port     = local.environments[terraform.workspace].rds.database == "mysql" ? 3306 : 5432
    protocol    = "tcp"
    cidr_blocks = [contains(["dev", "stage"], terraform.workspace) ? data.aws_vpc.default.cidr_block : local.environments[terraform.workspace].vpc_cidr_block]
  }

  ingress {
    description = "Antier IP"
    from_port   = local.environments[terraform.workspace].rds.database == "mysql" ? 3306 : 5432
    to_port     = local.environments[terraform.workspace].rds.database == "mysql" ? 3306 : 5432
    protocol    = "tcp"
    cidr_blocks = var.antiers_ip
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# create a rds subnet group after vpc is created
resource "aws_db_subnet_group" "rds" {
  name       = "${terraform.workspace}-rds-${local.project_name}"
  subnet_ids = contains(["dev", "stage"], terraform.workspace) ? data.aws_subnets.default.ids : module.vpc[0].private_subnets
}

# create db
resource "aws_db_instance" "rds" {
  allocated_storage               = 50
  backup_retention_period         = 7
  copy_tags_to_snapshot           = true
  db_subnet_group_name            = aws_db_subnet_group.rds.id
  enabled_cloudwatch_logs_exports = local.environments[terraform.workspace].rds.cloudwatch_logs
  engine                          = local.environments[terraform.workspace].rds.database
  engine_version                  = local.environments[terraform.workspace].rds.version
  identifier                      = "${terraform.workspace}-rds-${local.project_name}"
  instance_class                  = local.environments[terraform.workspace].rds.instance_type
  max_allocated_storage           = 200
  monitoring_interval             = local.environments[terraform.workspace].rds.monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  parameter_group_name            = local.environments[terraform.workspace].rds.database == "mysql" ? aws_db_parameter_group.mysql[0].name : aws_db_parameter_group.postgres[0].name
  multi_az                        = local.environments[terraform.workspace].rds.multi_az
  performance_insights_enabled    = local.environments[terraform.workspace].rds.performance_insights_enabled
  publicly_accessible             = local.environments[terraform.workspace].rds.public
  storage_encrypted               = true
  storage_type                    = "gp3"
  username                        = local.environments[terraform.workspace].rds.database == "mysql" ? "admin" : "postgres"
  password                        = random_password.rds.result
  vpc_security_group_ids          = [aws_security_group.rds.id]
  skip_final_snapshot             = true
}

# create db replica
resource "aws_db_instance" "rds-replica" {
  count                           = local.environments[terraform.workspace].rds.replica.create == "true" ? local.environments[terraform.workspace].rds.replica.count : 0
  replicate_source_db             = aws_db_instance.rds.identifier
  identifier                      = "${terraform.workspace}-rds-replica-${count.index}-${local.project_name}"
  instance_class                  = local.environments[terraform.workspace].rds.replica.instance_type
  storage_type                    = "gp3"
  multi_az                        = local.environments[terraform.workspace].rds.replica.multi_az
  publicly_accessible             = local.environments[terraform.workspace].rds.public
  vpc_security_group_ids          = [aws_security_group.rds.id]
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = local.environments[terraform.workspace].rds.cloudwatch_logs
  monitoring_interval             = local.environments[terraform.workspace].rds.replica.monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  backup_retention_period         = 0
  performance_insights_enabled    = local.environments[terraform.workspace].rds.replica.performance_insights_enabled
  skip_final_snapshot             = true
}

# generate password for database 
resource "random_password" "rds" {
  length  = 16
  special = false
}

# store password in paramter store
resource "aws_ssm_parameter" "rds" {
  name  = "/${terraform.workspace}/rds/password"
  type  = "SecureString"
  value = random_password.rds.result
}