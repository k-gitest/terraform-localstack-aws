module "app_infrastructure" {
  source = "../../" # `terraform/` ディレクトリ（共通インフラ定義）をモジュールとして呼び出す

  # 環境固有の変数を共通インフラ定義に渡す
  environment = "dev"
  # aws_region  = var.aws_region # data "aws_region"で取得するなら渡す必要はない
  # ... その他の環境固有の変数
  github_access_token = ""
}