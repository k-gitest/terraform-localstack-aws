include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "root" {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../../modules//rds"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
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
  project_name = local.env_vars.locals.common_vars.project_name
  environment  = "dev"
  
  # 元設計のlocal.rds_configsに相当
  database_configs = {
    # ここに具体的なDB設定を記述
    # 元のlocals-database.tfの内容に基づく
  }
  
  # networkモジュールからの依存関係
  vpc_id                        = dependency.network.outputs.vpc_id
  db_subnet_ids                 = dependency.network.outputs.private_subnet_ids
  db_subnet_group_name          = dependency.network.outputs.db_subnet_group_name
  application_security_group_id = dependency.network.outputs.application_security_group_id
  database_security_group_id    = dependency.network.outputs.database_security_group_id
  
  tags = local.env_vars.locals.common_vars.common_tags
}