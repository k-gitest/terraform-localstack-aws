include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/amplify"
}

inputs = {
  app_name            = include.stack.locals.amplify_app.app_name
  repository_url      = include.stack.locals.amplify_app.repository_url
  build_spec          = include.stack.locals.amplify_app.build_spec
  custom_rules        = include.stack.locals.amplify_app.custom_rules
  branch_name         = "main"

  environment_variables = include.stack.locals.amplify_app.environment_variables
  branch_stage          = "PRODUCTION"

  github_oauth_token  = include.stack.locals.github_access_token
  environment         = include.stack.locals.environment

  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
