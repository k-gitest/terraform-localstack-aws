include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/amplify"
}

inputs = {
  environment   = local.environment
  project_name  = local.project_name
  repository    = "https://github.com/your-org/your-repo"
  branch        = "main"
  build_command = "npm run build"
  tags          = local.common_tags
}
