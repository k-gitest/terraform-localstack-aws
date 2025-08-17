include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/ecs"
}

inputs = {
  ecs_cluster = {
    name                      = "my-awesome-app-cluster-prod"
    enable_fargate            = true
    enable_container_insights = true
  }
}
