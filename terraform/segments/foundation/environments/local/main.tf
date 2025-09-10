module "app_infrastructure" {
  source = "../../"

  # 環境固有の変数を共通インフラ定義に渡す
  environment = "local"

  # aws_region  = var.aws_region # data "aws_region"で取得するなら渡す必要はない
  # ... その他の環境固有の変数
  github_access_token = var.github_access_token
  aurora_mysql_password = null
  aurora_postgres_password = null
  postgres_password = null
}