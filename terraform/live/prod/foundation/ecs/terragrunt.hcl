include "stack" {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/ecs-cluster"
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  cluster_name              = "your-project-prod-cluster"
  enable_fargate            = true
  enable_container_insights = true
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
