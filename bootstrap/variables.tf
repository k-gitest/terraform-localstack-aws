variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "my-project"
}

variable "github_repository" {
  description = "GitHubリポジトリ名（owner/repo形式）"
  type        = string
}

variable "environments" {
  description = "環境リスト"
  type        = list(string)
  default     = ["dev", "prod"]
}
