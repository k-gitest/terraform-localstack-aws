# terraform/terragrunt.hcl

locals {
  # ルートで共通の変数
  aws_region = "ap-northeast-1"
}

# すべてのモジュールで共通の include 設定
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    arguments = [
      "-var", "aws_region=${local.aws_region}"
    ]
  }
}

# 各環境の terragrunt.hcl から相対パスで module を参照できるようにする
inputs = {
  aws_region = local.aws_region
}
