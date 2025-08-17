include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/fargate"
}

inputs = {
  environment  = local.environment
  project_name = local.project_name
  cpu          = 512
  memory       = 1024
  replicas     = 1
  docker_image = "dev-fargate:latest"
  tags         = local.common_tags
}
