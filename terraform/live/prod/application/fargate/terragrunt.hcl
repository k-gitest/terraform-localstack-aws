include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/ecs-service-fargate"
}

dependency "ecs" {
  config_path = "../../foundation/ecs-cluster"
  mock_outputs = {
    cluster_name = "mock-cluster"
    cluster_arn = "arn:aws:ecs:region:account:cluster/mock-cluster"
  }
}

dependency "network" {
  config_path = "../../foundation/network"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
    db_subnet_group_name = "mock-subnet-group"
    application_security_group_id = "sg-mock-app"
    database_security_group_id = "sg-mock-db"
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    target_group_arns = {
      backend = "arn:aws:elasticloadbalancing:region:account:targetgroup/backend-tg/1234567890abcdef"
    }
  }
}

dependency "ecr" {
  config_path = "../../foundation/ecr"
  mock_outputs = {
    backend_repository_url = "123456789012.dkr.ecr.region.amazonaws.com/backend"
  }
}

inputs = {
  project_name                  = include.stack.locals.project_name
  environment                   = include.stack.locals.environment
  
  service_name = "${include.stack.locals.project_name}-backend-service-${include.stack.locals.environment}"

  cluster_name = dependency.ecs.outputs.cluster_name
  container_image = dependency.ecr.outputs.repository_url
  
  # リソース設定
  cpu = include.stack.locals.fargate_config.backend_cpu
  memory = include.stack.locals.fargate_config.backend_memory
  container_port = include.stack.locals.fargate_config.backend_port
  assign_public_ip = true

  # ネットワーク設定
  subnets = dependency.network.outputs.private_subnet_ids
  security_groups = [dependency.network.outputs.alb_security_group_id]
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # ALB統合
  enable_load_balancer = true
  target_group_arn = dependency.alb.outputs.target_group_arns.backend
  
  alb_security_group_id = dependency.network.outputs.alb_security_group_id
  database_security_group_id = dependency.network.outputs.database_security_group_id
  database_port = 5432
  enable_public_internet_egress = true
  
  # アプリケーション設定
  environment_variables = include.stack.locals.backend_env_vars
  secrets = include.stack.locals.backend_secrets
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
