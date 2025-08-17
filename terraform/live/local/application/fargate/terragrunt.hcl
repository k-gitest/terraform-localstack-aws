include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/fargate"
}

inputs = {
  environment  = local.environment
  project_name = local.project_name
  cpu          = 256
  memory       = 512
  replicas     = 1
  docker_image = "local-fargate:latest"
  tags         = local.common_tags
}
