# ECRリポジトリ設定
variable "repository_name" { # 必須
  description = "ECRリポジトリの名前"
  type        = string
}

variable "image_tag_mutability" {
  description = "リポジトリのタグ変更可能性設定。MUTABLE（変更可能）またはIMMUTABLE（変更不可）のいずれかを指定"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "イメージタグの変更可能性は、MUTABLEまたはIMMUTABLEのいずれかである必要があります。"
  }
}

variable "scan_on_push" {
  description = "リポジトリにプッシュされた後にイメージをスキャンするかどうか"
  type        = bool
  default     = true
}

# ライフサイクルポリシー設定
variable "enable_lifecycle_policy" {
  description = "ECRリポジトリのライフサイクルポリシーを有効にする"
  type        = bool
  default     = true
}

variable "untagged_image_expiry_days" {
  description = "タグなしイメージを保持する日数"
  type        = number
  default     = 1
}

variable "tagged_image_count_limit" {
  description = "保持するタグ付きイメージの数"
  type        = number
  default     = 10
}

# リポジトリポリシー設定
variable "enable_cross_account_access" {
  description = "ECRリポジトリへのクロスアカウントアクセスを有効にする"
  type        = bool
  default     = false
}

variable "allowed_account_ids" {
  description = "このリポジトリへのアクセスを許可するAWSアカウントIDのリスト"
  type        = list(string)
  default     = []
}

# タグ設定
variable "tags" {
  description = "リソースに割り当てるタグのマップ"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}

# 共通命名規則
variable "environment" {
  description = "環境名（例：dev、staging、prod）"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myapp"
}