include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true # 親のlocalsを使用する場合はtrue
}

terraform {
  source = "${include.stack.locals.module_root}/network"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//network?ref=v1.0.0"
}

# networkモジュールに渡す値の設定
inputs = {
  # 基本設定
  project_name = include.stack.locals.project_name
  environment  = include.stack.locals.environment
  
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