include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/application/s3"
}

inputs = {
  environment  = local.environment
  project_name = local.project_name
  bucket_name  = "${local.project_name}-assets-${local.environment}"
  tags         = local.common_tags
}
