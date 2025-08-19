include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

/*
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}
*/

terraform {
  source = "../../../../../modules//network"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

# dev環境では作成する
inputs = {
  # 基本設定
  project_name = local.env_vars.locals.common_vars.project_name
  environment  = "dev"
  
  # 元設計のlocal.network_configに相当
  vpc_cidr_block       = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  
  # タグ
  tags = merge(
    local.env_vars.locals.common_vars.common_tags,
    {
      Module = "network"
    }
  )
}