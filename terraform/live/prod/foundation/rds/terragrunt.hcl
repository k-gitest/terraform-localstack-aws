include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true # 親のlocalsを使用する場合はtrue
}

terraform {
  source = "${include.stack.locals.module_root}/rds"

  # modulesを別repo化 & git::参照にする場合は//にする
  # source = "git::https://github.com/org/terraform-modules.git//rds?ref=v1.0.0"
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
    main_postgres = merge(
      # lookup(map, key, default) defaultはkeyがmap内に存在しなかった場合に返されるデフォルト値
      lookup(include.stack.locals.database_configs, "main_postgres", {}),
      {
        instance_class   = "db.t3.medium"
        storage          = 100
        skip_snapshot    = false
        backup_retention = 7
      }
    )
  }
}

inputs = {
  # 基本設定
  environment  = include.stack.locals.environment
  project_name = include.stack.locals.project_name

  database_configs = local.merged_database_configs

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
