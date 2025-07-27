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