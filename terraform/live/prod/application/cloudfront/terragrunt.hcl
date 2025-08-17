include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/cloudfront"
}

inputs = {
  environment   = local.environment
  project_name  = local.project_name
  origin_domain = "${local.project_name}-assets-${local.environment}.s3.amazonaws.com"
  tags          = local.common_tags
}
