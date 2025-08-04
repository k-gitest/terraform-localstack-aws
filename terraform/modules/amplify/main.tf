resource "aws_amplify_app" "this" {
  name        = var.app_name
  repository  = var.repository_url
  oauth_token = var.github_oauth_token # GitHubなどのPrivateリポジトリの場合必須
  platform    = var.platform # "WEB" または "WEB_COMPUTE" (SSR用)

  # ビルドスペック
  build_spec = var.build_spec

  # 環境変数 (任意)
  environment_variables = var.environment_variables

  # カスタムルール (任意: SPAのルート設定など)
  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      source = custom_rule.value.source
      target = custom_rule.value.target
      status = custom_rule.value.status
    }
  }

  tags = var.tags
}

# デフォルトブランチまたは指定されたブランチ
resource "aws_amplify_branch" "this" {
  app_id      = aws_amplify_app.this.id
  branch_name         = var.branch_name
  stage               = var.branch_stage # DEVELOPMENT, PRODUCTION, STAGING, EXPERIMENTAL, AUTODETECT
  enable_auto_build   = var.enable_auto_build # デフォルトでtrueが望ましい

  # display_nameとframeworkはaws_amplify_branchの有効な属性です
  display_name        = var.branch_display_name
  framework           = var.branch_framework

  # 注意: プルリクエストプレビューを有効にする、またはその設定を調整するには、
  # 通常、ブランチが作成された後にAWS Amplify Console UIを使用するか、
  # プロジェクトのセットアップに適用可能な場合は、より高度なAmplify CLI / Gen 2の設定を検討してください。
}