variable "app_name" {
  description = "Amplify application name."
  type        = string
}

variable "repository_url" {
  description = "URL of the Git repository for the Amplify app."
  type        = string
}

variable "github_oauth_token" {
  description = "GitHub OAuth token for private repositories. Consider using Secrets Manager or environment variables for sensitive data."
  type        = string
  sensitive   = true
}

variable "platform" {
  description = "Platform of the Amplify app. Can be WEB or WEB_COMPUTE (for SSR)."
  type        = string
  default     = "WEB"
}

variable "build_spec" {
  description = "Custom build specification for the Amplify app. If null, Amplify uses default build settings."
  type        = string
  default     = null # nullをデフォルトにして任意にする
}

variable "environment_variables" {
  description = "Environment variables for the Amplify app."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "The deployment environment received from the root module."
  type        = string
}

variable "custom_rules" {
  description = "List of custom redirect/rewrite rules for the Amplify app."
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
  description = "A map of tags to assign to the Amplify app."
  type        = map(string)
  default     = {}
}

variable "branch_name" {
  description = "Name of the branch to connect to the Amplify app."
  type        = string
  default     = "main" # デフォルトブランチ名
}

variable "branch_stage" {
  description = "The stage for the branch, e.g., DEVELOPMENT, PRODUCTION."
  type        = string
  default     = "DEVELOPMENT"
}

variable "enable_auto_build" {
  description = "Enables auto building for the branch."
  type        = bool
  default     = true
}

variable "branch_display_name" {
  description = "Display name for the branch."
  type        = string
  default     = null
}

variable "branch_framework" {
  description = "Framework for the branch (e.g., REACT, NEXTJS)."
  type        = string
  default     = null
}

variable "enable_auto_pr_with_fork_branches" {
  description = "Enables auto building of branches from a fork repository."
  type        = bool
  default     = false # 通常はfalseが安全
}

variable "enable_pull_request_preview" {
  description = "Enables pull request previews for the branch."
  type        = bool
  default     = false
}

variable "pull_request_preview_repository_name" {
  description = "Name of the repository to use for pull request previews (if different from main repository)."
  type        = string
  default     = null
}