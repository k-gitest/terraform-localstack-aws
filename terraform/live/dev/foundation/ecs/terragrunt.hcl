include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

include "root" {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../../modules//ecs-cluster"
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
  }
}

inputs = {
  # 元設計のlocal.ecs_clusterに相当
  cluster_name              = "your-project-dev-cluster"  # または動的に設定
  enable_fargate           = true
  enable_container_insights = true
  
  environment  = "dev"
  project_name = local.env_vars.locals.common_vars.project_name
  
  tags = local.env_vars.locals.common_vars.common_tags
}