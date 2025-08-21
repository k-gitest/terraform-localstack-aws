include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true # 親のlocalsを使用する場合はtrue
}

terraform {
  source = "${include.stack.locals.module_root}/ecr"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//ecr?ref=v1.0.0"
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  repository_name = "backend"
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}