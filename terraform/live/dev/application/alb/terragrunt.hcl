include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/alb"
}

inputs = {
  environment     = local.environment
  project_name    = local.project_name
  listener_port   = 80
  target_port     = 8080
  health_check    = "/health"
  tags            = local.common_tags
}
