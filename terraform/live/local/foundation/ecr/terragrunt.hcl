include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/ecr"
}

inputs = {
  ecr_repositories = {
    backend          = "${local.project_name}-backend"
    frontend         = "${local.project_name}-frontend"
    image_processor  = "${local.project_name}-image-processor"
  }
}
