variable "app_name" {
  description = "Amplifyアプリケーションの名前"
  type        = string
}

variable "repository_url" {
  description = "AmplifyアプリのGitリポジトリのURL"
  type        = string
}

variable "github_oauth_token" {
  description = "プライベートリポジトリ用のGitHub OAuthトークン。機密データはSecrets Managerや環境変数の使用を検討してください。"
  type        = string
  sensitive   = true
}

variable "platform" {
  description = "Amplifyアプリのプラットフォーム。WEB または WEB_COMPUTE（SSR用）を指定できます。"
  type        = string
  default     = "WEB"
}

variable "build_spec" {
  description = "Amplifyアプリのカスタムビルド仕様。nullの場合、Amplifyはデフォルトのビルド設定を使用します。"
  type        = string
  default     = null # nullをデフォルトにして任意にする
}

variable "environment" {
  description = "Terraformの実行環境（例：local、development、production）"
  type        = string
  default     = "development"
}

variable "environment_variables" {
  description = "Amplifyアプリの環境変数"
  type        = map(string)
  default     = {}
}

variable "custom_rules" {
  description = "Amplifyアプリのカスタムリダイレクト/リライトルールのリスト"
  type = list(object({
    source = string
    target = string
    status = string
  }))
  default = [
    {
      source = "/<*>"
      target = "/index.html"
      status = "200"
    } # SPAのデフォルトルール
  ]
}

variable "tags" {
  description = "Amplifyアプリに割り当てるタグのマップ"
  type        = map(string)
  default     = {}
}

variable "branch_name" {
  description = "Amplifyアプリに接続するブランチの名前"
  type        = string
  default     = "main" # デフォルトブランチ名
}

variable "branch_stage" {
  description = "ブランチのステージ（例：DEVELOPMENT、PRODUCTION）"
  type        = string
  default     = "DEVELOPMENT"
}

variable "enable_auto_build" {
  description = "ブランチの自動ビルドを有効にする"
  type        = bool
  default     = true
}

variable "branch_display_name" {
  description = "ブランチの表示名"
  type        = string
  default     = null
}

variable "branch_framework" {
  description = "ブランチのフレームワーク（例：REACT、NEXTJS）"
  type        = string
  default     = null
}