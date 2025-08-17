include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/ecs"
}

inputs = {
  ecs_cluster = {
    name                     = "${local.project_name}-cluster-${local.environment}"
    enable_fargate            = true
    enable_container_insights = false
  }
}
