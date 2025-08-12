# ネットワークモジュール
module "network" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/network"
  
  project_name = var.project_name
  environment = var.environment
  
  vpc_cidr_block = local.network_config.vpc_cidr
  public_subnet_cidrs = local.network_config.public_subnet_cidrs
  private_subnet_cidrs = local.network_config.private_subnet_cidrs
  
  tags = local.common_tags
}

# ECRモジュール
module "ecr" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/ecr"
  
  repository_name = local.ecr_repositories.backend
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# ECSクラスターモジュール
module "ecs_cluster" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/ecs-cluster"
  
  cluster_name = local.ecs_cluster.name
  enable_fargate = local.ecs_cluster.enable_fargate
  enable_container_insights = local.ecs_cluster.enable_container_insights
  
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# RDSデータベース
module "rds_databases" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/rds"
  
  project_name = var.project_name
  environment = var.environment
  database_configs = try(local.rds_configs, {})
  
  vpc_id = module.network[0].vpc_id
  db_subnet_ids = module.network[0].private_subnet_ids
  db_subnet_group_name = module.network[0].db_subnet_group_name
  application_security_group_id = module.network[0].application_security_group_id
  database_security_group_id = module.network[0].database_security_group_id
  
  tags = local.common_tags
}

# Auroraクラスター
module "aurora_clusters" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/aurora"
  
  project_name = var.project_name
  environment = var.environment
  aurora_configs = try(local.aurora_configs, {})
  
  vpc_id                        = module.network[0].vpc_id
  db_subnet_ids                 = module.network[0].private_subnet_ids
  db_subnet_group_name          = module.network[0].db_subnet_group_name
  application_security_group_id = module.network[0].application_security_group_id
  database_security_group_id    = module.network[0].database_security_group_id
  
  tags = local.common_tags
}
