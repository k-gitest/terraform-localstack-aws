include "stack" {
  path = find_in_parent_folders()
}

terraform {
  source = "${include.stack.locals.module_root}/network"
}

inputs = {
  # 基本設定
  project_name = include.stack.locals.project_name
  environment  = include.stack.locals.environment

  vpc_cidr_block       = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
