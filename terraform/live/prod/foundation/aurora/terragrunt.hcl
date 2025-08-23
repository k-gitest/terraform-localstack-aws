include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/aurora"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//aurora?ref=v1.0.0"
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

locals {
  merged_database_configs = {
    aurora_configs = merge(
      # lookup(map, key, default) defaultはkeyがmap内に存在しなかった場合に返されるデフォルト値
      lookup(include.stack.locals.aurora_configs, "main_aurora_postgres", {}),
      {
        instances = {
        writer = {
          class = "db.t3.micro"
          public = true
        }
        reader = null
      }
      backup_retention = 0
      deletion_protection = false
      skip_snapshot = true
      performance_insights = false
      monitoring_interval = 0
      
      serverlessv2_scaling = null
      }
    )
  }
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  aurora_configs = merged_database_configs

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
