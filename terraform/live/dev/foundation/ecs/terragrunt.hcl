include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true # 親のlocalsを使用する場合はtrue
}

terraform {
  source = "${include.stack.locals.module_root}/ecs-cluster"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//ecs-cluster?ref=v1.0.0"
}

# networkモジュールに依存
/*
dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
}
*/

# ecs-clusterに渡す値の設定
inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  cluster_name              = "your-project-dev-cluster"
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