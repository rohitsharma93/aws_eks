# create eks cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.19.0"

  cluster_name    = "${terraform.workspace}-eks-${local.project_name}"
  cluster_version = local.environments[terraform.workspace].eks.version

  # Manage aws-auth configmap
  manage_aws_auth_configmap = true

  # Currently we allow EKS management access via the public internet
  # In the future, we need to restrict this to company's VPN
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  vpc_id                          = contains(["dev", "stage"], terraform.workspace) ? data.aws_vpcs.default.ids[0] : module.vpc[0].vpc_id
  subnet_ids                      = contains(["dev", "stage"], terraform.workspace) ? data.aws_subnets.default.ids : module.vpc[0].private_subnets


  # IAM Roles for Service Account (IRSA) enables applications running in clusters to authenticate with AWS services using IAM roles.
  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type                               = "AL2_x86_64"
    create_launch_template                 = true
    update_launch_template_default_version = true

    # Attach IAM policies to nodes
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      SecretsManagerReadOnly       = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
      s3fullaccess                 = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }

    subnet_ids = contains(["dev", "stage"], terraform.workspace) ? data.aws_subnets.default.ids : module.vpc[0].private_subnets

    # Define the EBS volume type and size for worker nodes
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 30
          volume_type = "gp3"
          encrypted   = true

          delete_on_termination = true
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "${terraform.workspace}-eks-${local.project_name}"
      min_size       = 1
      max_size       = 5
      desired_size   = 1
      instance_types = [local.environments[terraform.workspace].eks.instance_type]
      capacity_type  = "ON_DEMAND"
      ebs_optimized  = true
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        SecretsManagerReadOnly       = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
        s3fullaccess                 = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      }
    }
  }
  cluster_addons = {
    # EBS CSI driver is required for persistent volumes of gp3 type to work
    aws-ebs-csi-driver = {
      addon_version            = local.environments[terraform.workspace].eks.ebs_csi_driver_version
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
}

# This module creates an IAM role for the EBS CSI driver
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "EBS_CSI_DRIVER_ROLE"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# This command updates kube config context credentials
resource "null_resource" "setup_kube_config" {
  provisioner "local-exec" {
    command = "aws eks --region ${local.environments[terraform.workspace].region} update-kubeconfig --name ${module.eks.cluster_name} --profile ${local.environments[terraform.workspace].account_id} && sed -i 's/<cluster_name>/${module.eks.cluster_name}/g' Argo/Application/alb.yaml "
  }
}
