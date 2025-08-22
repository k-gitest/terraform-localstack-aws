include "stack" {
  path = find_in_parent_folders()
}

terraform {
  source = "${include.stack.locals.module_root}/ecs-cluster"
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  cluster_name              = "your-project-local-cluster"
  enable_fargate            = true
  enable_container_insights = false
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
