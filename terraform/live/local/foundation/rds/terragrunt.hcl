include "stack" {
  path = find_in_parent_folders()
}

terraform {
  source = "${include.stack.locals.module_root}/rds"
}

# network モジュールに依存
dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    db_subnet_group_name = "mock-subnet-group"
    application_security_group_id = "sg-mock-app"
    database_security_group_id = "sg-mock-db"
  }
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name
  
  database_configs = include.stack.locals.database_configs
  
  # networkモジュールからの依存関係
  vpc_id                        = dependency.network.outputs.vpc_id
  db_subnet_ids                 = dependency.network.outputs.private_subnet_ids
  db_subnet_group_name          = dependency.network.outputs.db_subnet_group_name
  application_security_group_id = dependency.network.outputs.application_security_group_id
  database_security_group_id    = dependency.network.outputs.database_security_group_id
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
