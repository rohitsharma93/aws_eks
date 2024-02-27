# generate alb file
resource "local_file" "alb" {
  content  = data.template_file.alb.rendered
  filename = "Argo/Application/${terraform.workspace}_alb.yaml"
}

# generate loki file
resource "local_file" "loki" {
  content  = data.template_file.loki.rendered
  filename = "Argo/Application/${terraform.workspace}_loki.yaml"
}