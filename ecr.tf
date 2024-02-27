# create ecr repositories
resource "aws_ecr_repository" "repo" {
  for_each             = toset(local.environments[terraform.workspace].ecr)
  name                 = "${terraform.workspace}-${each.key}-${local.project_name}"
  image_tag_mutability = "MUTABLE"
}