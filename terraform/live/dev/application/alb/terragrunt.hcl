include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/alb"
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
  project_name = include.stack.locals.project_name
  environment = include.stack.locals.environment
  
  alb_name = include.stack.locals.alb_config.name
  internal = include.stack.locals.alb_config.internal
  
  # networkモジュールからの依存関係
  subnets = dependency.network.outputs.public_subnet_ids
  security_groups = [dependency.network.outputs.alb_security_group_id]
  vpc_id = dependency.network.outputs.vpc_id
  
  target_groups = include.stack.locals.alb_config.target_groups
  default_target_group = include.stack.locals.alb_config.default_target_group
  listener_rules = include.stack.locals.alb_config.listener_rules
  
  enable_https = include.stack.locals.env_config.enable_https
  enable_deletion_protection = include.stack.locals.alb_config.enable_deletion_protection
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
