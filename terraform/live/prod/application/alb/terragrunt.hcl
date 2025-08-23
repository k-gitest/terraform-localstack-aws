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

locals {
  target_groups = {
    backend = merge(
      lookup(include.stack.locals.alb_config.target_groups, "backend", {}),
      {
        deregistration_delay = 60
        health_check = merge(
          lookup(include.stack.locals.alb_config.target_groups.backend, "health_check", {}),
          {
            interval = 15
          }
        )
      }
    )
    frontend = merge(
      lookup(include.stack.locals.alb_config.target_groups, "frontend", {}),
      {
        deregistration_delay = 60
        health_check = merge(
          lookup(include.stack.locals.alb_config.target_groups.frontend, "health_check", {}),
          {
            interval = 10
          }
        )
      }
    )
  }
}

inputs = {
  project_name = var.project_name
  environment = var.environment
  
  alb_name = include.stack.locals.alb_config.name
  internal = include.stack.locals.alb_config.internal
  
  # networkモジュールからの依存関係
  subnets = dependency.network.outputs.public_subnet_ids
  security_groups = [dependency.network.outputs.alb_security_group_id]
  vpc_id = dependency.network.outputs.vpc_id
  
  target_groups = local.target_groups
  
  default_target_group = include.stack.locals.alb_config.default_target_group
  listener_rules = include.stack.locals.alb_config.listener_rules
  
  enable_https = true
  enable_deletion_protection = true
  enable_access_logs = true
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
