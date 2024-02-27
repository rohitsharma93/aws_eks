# create pipelines
resource "aws_codepipeline" "codepipeline" {
  for_each = { for pipeline in local.environments[terraform.workspace].codepipeline.pipelines : pipeline["Name"] => pipeline }
  name     = "${terraform.workspace}-${each.value.Name}-${local.project_name}"
  role_arn = aws_iam_role.codepipeline_role[0].arn
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline[0].id
  }
  stage {
    name = "Source"
    action {
      name      = "Source"
      category  = "Source"
      owner     = "AWS"
      provider  = "CodeStarSourceConnection"
      version   = "1"
      run_order = "1"
      configuration = {
        BranchName       = each.value.Branch
        ConnectionArn    = aws_codestarconnections_connection.github[0].arn
        FullRepositoryId = each.value.Repo
      }
      output_artifacts = ["SourceArtifact"]
      region           = local.environments[terraform.workspace].region
      namespace        = "SourceVariables"
    }
  }
  stage {
    name = "Build"
    action {
      name      = "Build"
      category  = "Build"
      owner     = "AWS"
      provider  = "CodeBuild"
      version   = "1"
      run_order = "1"
      configuration = {
        EnvironmentVariables = jsonencode([
          { 
            name = "ECR_REPO_NAME"
            type = "PLAINTEXT"
            value = "${terraform.workspace}-${each.value.ECR}-${local.project_name}" 
          }
        ])
        ProjectName = "${terraform.workspace}-build-${local.project_name}"
      }
      output_artifacts = ["BuildArtifact"]
      input_artifacts  = ["SourceArtifact"]
      region           = local.environments[terraform.workspace].region
      namespace        = "BuildVariables"

    }
  }
}

#setup github connection
resource "aws_codestarconnections_connection" "github" {
  count         = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  name          = "${terraform.workspace}-github-${local.project_name}"
  provider_type = "GitHub"
}