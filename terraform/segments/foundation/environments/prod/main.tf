module "app_infrastructure" {
  source = "../../"

  environment = "prod"

  github_access_token = ""
  aurora_mysql_password = {}
  aurora_postgres_password = {}
  postgres_password = {}
}