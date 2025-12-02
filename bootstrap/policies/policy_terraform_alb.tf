# ===================================
# ALB/ELB関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  alb_common_statements = [
    {
      Sid    = "ALBReadAccess"
      Effect = "Allow"
      Action = [
        # ロードバランサー
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        # ターゲットグループ
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        # リスナー
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeListenerCertificates",
        # ルール
        "elasticloadbalancing:DescribeRules",
        # SSL証明書
        "elasticloadbalancing:DescribeSSLPolicies",
        # タグ
        "elasticloadbalancing:DescribeTags",
        # アカウント制限
        "elasticloadbalancing:DescribeAccountLimits"
      ]
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  alb_dev_management_statements = [
    # ロードバランサー管理（削除含む）
    {
      Sid    = "LoadBalancerManagementDev"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-dev-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-dev-*"
      ]
    },

    # ターゲットグループ管理（削除含む）
    {
      Sid    = "TargetGroupManagementDev"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-dev-*"
      ]
    },

    # リスナー管理（削除含む）
    {
      Sid    = "ListenerManagementDev"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/${var.project_name}-dev-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/${var.project_name}-dev-*"
      ]
    },

    # リスナールール管理（削除含む）
    {
      Sid    = "RuleManagementDev"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:SetRulePriorities",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/${var.project_name}-dev-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/${var.project_name}-dev-*"
      ]
    },
    
    # ターゲット登録時の追加権限（EC2/ECS用 - 条件付き）
    {
      Sid    = "TargetRegistrationConditionalDev"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-dev-*"
      ]
      Condition = {
        StringEquals = {
          "elasticloadbalancing:TargetType": [
            "instance", 
            "ip"
          ]
        }
      }
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  alb_prod_management_statements = [
    # ロードバランサー管理（作成・変更のみ - 削除除外）
    {
      Sid    = "LoadBalancerManagementProd"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateLoadBalancer",
        # "elasticloadbalancing:DeleteLoadBalancer", # ❌ 除外
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-prod-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-prod-*"
      ]
    },

    # ターゲットグループ管理（作成・変更のみ - 削除除外）
    {
      Sid    = "TargetGroupManagementProd"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateTargetGroup",
        # "elasticloadbalancing:DeleteTargetGroup", # ❌ 除外
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-prod-*"
      ]
    },

    # リスナー管理（削除は設定変更のため許容）
    {
      Sid    = "ListenerManagementProd"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",  # SSL証明書更新時に必要
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/${var.project_name}-prod-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/${var.project_name}-prod-*"
      ]
    },

    # リスナールール管理（削除含む）
    {
      Sid    = "RuleManagementProd"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:SetRulePriorities",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/${var.project_name}-prod-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/${var.project_name}-prod-*"
      ]
    },
    
    # ターゲット登録時の追加権限（EC2/ECS用 - 条件付き）
    {
      Sid    = "TargetRegistrationConditionalProd"
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-prod-*"
      ]
      Condition = {
        StringEquals = {
          "elasticloadbalancing:TargetType": [
            "instance", 
            "ip"
          ]
        }
      }
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  alb_local_management_statements = local.alb_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_alb = {
    local = concat(
      local.alb_common_statements,
      local.alb_local_management_statements
    ),
    dev = concat(
      local.alb_common_statements,
      local.alb_dev_management_statements
    ),
    prod = concat(
      local.alb_common_statements,
      local.alb_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.alb_common_statements,
      local.alb_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "alb_policy_statement_counts" {
  description = "各環境のALBポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_alb :
    env => length(statements)
  }
}

output "alb_policy_summary" {
  description = "各環境のALBポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*と同等のフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-* リソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prod-* リソースへの作成・変更権限のみ（LB/TG削除は不可）"
    default = "デフォルト（開発環境と同等）"
  }
}