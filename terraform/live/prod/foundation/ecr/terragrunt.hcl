include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/ecr"
}

inputs = {
  ecr_repositories = {
    backend          = "my-awesome-app-backend"
    frontend         = "my-awesome-app-frontend"
    image_processor  = "my-awesome-app-image-processor"
  }
}
