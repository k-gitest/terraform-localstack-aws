include "stack" {
  path = find_in_parent_folders()
}

terraform {
  source = "${include.stack.locals.module_root}/ecr"
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
