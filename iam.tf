# Create IAM Role for SSM
resource "aws_iam_role" "ssm" {
  name = "${terraform.workspace}_custom_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com",
        },
      },
    ],
  })
}

# Attach IAM Policy to IAM Role 
resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm.name
}

# IAM Instance Profile to Connect to Instance
resource "aws_iam_instance_profile" "ssm" {
  name = "${terraform.workspace}_ssm_instance_profile"
  role = aws_iam_role.ssm.name
}

# Create IAM Role for CloudWatch and RDS
resource "aws_iam_role" "rds_monitoring" {
  name = "${title(terraform.workspace)}RDSMonitoringRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com",
        },
      },
    ],
  })
}

# Attach IAM Policies to CloudWatch and RDS Role
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.rds_monitoring.name
}

# create iam role for codebuild
resource "aws_iam_role" "codebuild_role" {
  count = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name  = "${title(terraform.workspace)}CodeBuildRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com",
        },
      },
    ],
  })
}

# create iam policy for codebuild
resource "aws_iam_policy" "codebuild_policy" {
  count       = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name        = "${title(terraform.workspace)}CodeBuildPolicy"
  path        = "/"
  description = "${title(terraform.workspace)}CodeBuildPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
        "logs:PutLogEvents"],
        Effect = "Allow",
        Resource = [
          "arn:aws:logs:${local.environments[terraform.workspace].region}:${local.environments[terraform.workspace].account_id}:log-group:/aws/codebuild/${terraform.workspace}-build-${local.project_name}",
          "arn:aws:logs:${local.environments[terraform.workspace].region}:${local.environments[terraform.workspace].account_id}:log-group:/aws/codebuild/${terraform.workspace}-build-${local.project_name}:*",
        ]
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
        "s3:GetBucketLocation"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::codepipeline-${local.environments[terraform.workspace].region}-*",
        ]
      },
      {
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"],
        Effect = "Allow",
        Resource = [
          "arn:aws:codebuild:${local.environments[terraform.workspace].region}:${local.environments[terraform.workspace].account_id}:report-group/${terraform.workspace}-build-${local.project_name}*",
        ]
      },
      {
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "eks:DescribeCluster",
        "eks:ListClusters"],
        Effect = "Allow",
        Resource = [
          "*",
        ]
      }
    ],
  })
}

# attach code build policy to role
resource "aws_iam_role_policy_attachment" "codebuild_policy-attach" {
  count      = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  role       = aws_iam_role.codebuild_role[0].name
  policy_arn = aws_iam_policy.codebuild_policy[0].arn
}


# create iam role for codepipeline
resource "aws_iam_role" "codepipeline_role" {
  count = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name  = "${title(terraform.workspace)}CodepipelineRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com",
        },
      },
    ],
  })
}

# create iam policy for codepipeline
resource "aws_iam_policy" "codepipeline_policy" {
  count       = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name        = "${title(terraform.workspace)}CodepipelinePolicy"
  path        = "/"
  description = "${title(terraform.workspace)}CodepipelinePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codestar-connections:UseConnection",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Effect = "Allow",
        Resource = [
          "*"
        ]
      }
    ],
  })
}

# attach code pipeline policy to role
resource "aws_iam_role_policy_attachment" "codepipeline_policy-attach" {
  count      = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_policy[0].arn
}