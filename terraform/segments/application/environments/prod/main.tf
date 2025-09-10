module "app_infrastructure" {
  source = "../../"

  environment = "prod"

  # コンテナイメージをコマンドライン引数から受け取る
  container_image = var.container_image

  github_access_token = ""
  aurora_mysql_password = {}
  aurora_postgres_password = {}
  postgres_password = {}
}