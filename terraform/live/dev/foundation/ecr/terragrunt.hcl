include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "root" {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../../modules//ecr"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  # 元設計のlocal.ecr_repositoriesに相当
  repository_name = "backend"  # または動的に設定
  environment     = "dev"
  project_name    = local.env_vars.locals.common_vars.project_name
  
  tags = local.env_vars.locals.common_vars.common_tags
}