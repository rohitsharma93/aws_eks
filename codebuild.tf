# create build project 
resource "aws_codebuild_project" "codebuild_backend" {
  count        = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name         = "${terraform.workspace}-build-${local.project_name}"
  description  = "${terraform.workspace}-build-${local.project_name}"
  service_role = aws_iam_role.codebuild_role[0].arn
  source {
    type         = "CODEPIPELINE"
    buildspec    = data.local_file.buildspec_local.content
    insecure_ssl = false
  }
  artifacts {
    type      = "CODEPIPELINE"
    name      = "${terraform.workspace}-build-${local.project_name}"
    packaging = "NONE"
  }
  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = local.environments[terraform.workspace].region
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.environments[terraform.workspace].account_id
      type  = "PLAINTEXT"
    }
  }
}
