terraform {
  required_version = "~> 1.7.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"
    }
  }
  backend "s3" { # replace <account_id> with your aws account id 
    bucket         = "terraform-state-files-<account_id>-infrastructure-terraform"
    key            = "env-terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-statefile-locks-<account_id>-env"
    encrypt        = true
    profile        = "<account_id>"
  }
}
provider "aws" {
  region  = local.environments[terraform.workspace].region
  profile = local.environments[terraform.workspace].account_id
  default_tags {
    tags = {
      Environment = terraform.workspace
      terraform   = "managed"
    }
  }
}


# Kubernetes provider. It requires awscli to be installed locally where Terraform is executed
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", local.environments[terraform.workspace].account_id]
  }
}

# Helm provider. It requires awscli to be installed locally where Terraform is executed
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", local.environments[terraform.workspace].account_id]
    }
  }
}