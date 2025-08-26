variable "aws_region" {
  description = "リソースをデプロイするAWSリージョン"
  type        = string
  default     = "ap-northeast-1" # LocalStack で一般的に使用されるリージョン
}

variable "github_access_token" {
  description = "プライベートリポジトリ用のGitHub OAuthトークン（Amplify用）。環境変数またはシークレットマネージャーからの読み込みを推奨"
  type        = string
  sensitive   = true
}

# ECR/ECS/Fargateの変数設定
variable "environment" {
  description = "環境名（例：local、dev、staging、prod）"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "my-backend-app" # プロジェクト名を具体的に
}

variable "tags" {
  description = "すべてのリソースに割り当てるタグのマップ"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

# RDSの変数設定
variable "postgres_password" {
  description = "Password for PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "mysql_password" {
  description = "Password for MySQL database"
  type        = string
  sensitive   = true
  default     = ""
}

variable "reporting_db_password" {
  description = "Password for reporting database"
  type        = string
  sensitive   = true
  default     = ""
}

# Aurora PostgreSQL マスターパスワード
variable "aurora_postgres_password" {
  description = "Aurora PostgreSQL クラスターのマスターパスワード"
  type        = string
  sensitive   = true
}

# Aurora MySQL マスターパスワード
variable "aurora_mysql_password" {
  description = "Aurora MySQL クラスターのマスターパスワード"
  type        = string
  sensitive   = true
}

variable "user_content_s3_buckets" {
  description = "User content S3 buckets for image processing"
  type        = list(object({
    bucket_name = string
    bucket_arn  = string
  }))
  default     = []
  
}