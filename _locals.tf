locals {
  name         = "${terraform.workspace}-projectname" # Terraform Name  
  environment  = terraform.workspace                  # Environment
  project_name = "projectname"                        # Project Name
  environments = {
    dev = {
      region         = "eu-central-1"  # Region For Dev Environment
      account_id     = "312996103805"  # Account Id we want to provision resources
      vpc_cidr_block = "172.31.0.0/16" # Do not change it for dev & stage enironments. Make sure you keep the cidr range private and different for all environments except dev & stage 
      redis = {
        enabled       = "true"      # set "false" if not wanted to create 
        instance_type = "t3.medium" # set redis instance type
      }
      rabbitmq = {
        enabled       = "true"      # set "false" if not wanted to create 
        instance_type = "t3.medium" # set rabbitmq instance type
      }
      jenkins = {
        enabled       = "true"      # only enable if not using github for code, else set "false"
        instance_type = "t3.medium" # set jenkins instance type
        # jenkins password will be store in /var/lib/jenkins/secrets/initailAdminPassword
      }
      codepipeline = {
        enabled = "true" # only enable if using github for code, else set "false"
        pipelines = [
          {             #comment if not wanted to create any pipeline
            Name   = "" # define pipleine name
            Branch = "" # define branch name
            Repo   = "" # define full repo name eg: <guthub_username_or_org_name>/<repo_name>
            ECR    = "" # ecr name where docker image will be pushed
          }
        ]
      }
      rds = {
        database                     = "mysql"                                    # set "postgres" if want to create postgres db
        instance_type                = "db.t3.medium"                             # set db instance type
        cloudwatch_logs              = ["audit", "error", "general", "slowquery"] # for postgress set ["postgresql","upgrade"]
        version                      = "8.0.33"                                   # for postgress set "14.7"
        monitoring_interval          = 30                                         # set 0 to disable
        multi_az                     = false                                      # set true to enable
        performance_insights_enabled = false                                      # set true to enable, Note: cannot be set true, if db size is small or nano
        public                       = false                                      # set true to enable
        replica = {
          create                       = "true"         # set "false" if not wanted to create 
          count                        = 1              # set number of replicas to be created
          instance_type                = "db.t3.medium" # set db replica instance type
          multi_az                     = false          # set true to enable
          monitoring_interval          = 30             # set 0 to disable
          performance_insights_enabled = false          # set true to enable, Note: cannot be set true, if db size is small or nano
        }
      }
      eks = {
        version                = "1.28"               # eks version
        instance_type          = "t3.medium"          # set eks node types
        ebs_csi_driver_version = "v1.26.0-eksbuild.1" # ebs csi driver version
      }
      ecr = [] # provide ecr repo name to be created like explorer-frontend, explorer-backend. Do not pass environment or project name. It will be passed automaticallu
    }
  }
}
# Subnets
locals {
  first_two_octets = join(".", slice(split(".", local.environments[terraform.workspace].vpc_cidr_block), 0, 2))
  public_subnet_ids = [
    for i in range(length(data.aws_availability_zones.available.names)) : "${local.first_two_octets}.${i + 1}.0/24"
  ]
  private_subnet_ids = [
    for i in range(length(data.aws_availability_zones.available.names)) : "${local.first_two_octets}.${i + 10}.0/24"
  ]
}
