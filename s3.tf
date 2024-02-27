#create bucket to store loki logs
resource "aws_s3_bucket" "loki" {
  bucket = "${terraform.workspace}-loki-${local.project_name}"
  tags = {
    Name = "${terraform.workspace}-loki-${local.project_name}"
  }
}

# enable versioning for loki bucket
resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration {
    status = "Enabled"
  }
}

# delete objects after 90 days in loki bucket
resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    status = "Enabled"
    id     = "delete objects older than 90 days"
    expiration {
      days = "90"
    }
  }
}

#create bucket to store codepipeline artifacts
resource "aws_s3_bucket" "codepipeline" {
  count  = local.environments[terraform.workspace].codepipeline.enabled == "true" ? 1 : 0
  bucket = "${terraform.workspace}-codepipeline-${local.project_name}"
  tags = {
    Name = "${terraform.workspace}-codepipeline-${local.project_name}"
  }
}