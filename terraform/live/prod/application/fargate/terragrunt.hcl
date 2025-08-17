include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/fargate"
}

inputs = {
  environment  = local.environment
  project_name = local.project_name
  cpu          = 1024
  memory       = 2048
  replicas     = 3
  docker_image = "prod-fargate:latest"
  tags         = local.common_tags
}
