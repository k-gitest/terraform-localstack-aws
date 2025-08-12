locals {
  # ECRリポジトリ設定
  ecr_repositories = {
    backend = "${var.project_name}-backend"
    frontend = "${var.project_name}-frontend"
    image_processor = "${var.project_name}-image-processor"
  }

  # ECSクラスター設定
  ecs_cluster = {
    name = "${var.project_name}-cluster-${var.environment}"
    enable_fargate = true
    enable_container_insights = var.environment == "prod"
  }
}