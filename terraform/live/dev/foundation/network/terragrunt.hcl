include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true # 親のlocalsを使用する場合はtrue
}

/*
include "root" {
  path = find_in_parent_folders("root.hcl")
  # rootから直接取得する場合
  expose = true
}
*/

terraform {
  source = "${include.stack.locals.module_root}/network"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//network?ref=v1.0.0"
}

/* 別リポジトリのlocalsを使用する場合はread_terragrunt_configを使用すると良い
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl")) # 絶対・相対パス設定可能
}
*/

inputs = {
  # 基本設定
  project_name = include.stack.locals.project_name
  environment  = include.stack.locals.environment
  
  # 元設計のlocal.network_configに相当
  vpc_cidr_block       = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}