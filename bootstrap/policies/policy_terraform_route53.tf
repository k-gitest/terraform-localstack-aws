# ===================================
# Route53関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # 必須とするリクエストタグ
  required_request_tags = {
    "aws:RequestTag/Project": var.project_name,
    "aws:RequestTag/ManagedBy": "terraform"
  }
  
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  route53_common_statements = [
    {
      Sid    = "Route53ReadAccess"
      Effect = "Allow"
      Action = [
        # ホストゾーン
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName",
        "route53:GetHostedZoneCount",
        # レコードセット
        "route53:ListResourceRecordSets",
        "route53:GetChange",
        # ヘルスチェック
        "route53:GetHealthCheck",
        "route53:GetHealthCheckCount",
        "route53:GetHealthCheckStatus",
        "route53:ListHealthChecks",
        # トラフィックポリシー
        "route53:GetTrafficPolicy",
        "route53:ListTrafficPolicies",
        "route53:GetTrafficPolicyInstance",
        "route53:ListTrafficPolicyInstances",
        # タグ
        "route53:ListTagsForResource",
        "route53:ListTagsForResources"
      ]
      Resource = "*"
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（devタグを持つリソースへのフル管理）
  # ===================================
  route53_dev_management_statements = [
    # ホストゾーン作成（タグ付与を強制）
    {
      Sid    = "CreateHostedZoneDev"
      Effect = "Allow"
      Action = ["route53:CreateHostedZone"]
      Resource = "*"
      Condition = merge(
        local.required_request_tags,
        {
          StringEquals = {
            "aws:RequestTag/Environment": "dev"
          }
        }
      )
    },

    # ホストゾーン更新・削除（フル管理）
    {
      Sid    = "ManageHostedZoneDev"
      Effect = "Allow"
      Action = [
        "route53:UpdateHostedZoneComment",
        "route53:DeleteHostedZone", # 開発環境は削除可能
        "route53:ChangeTagsForResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    },
    
    # レコードセット管理（安全なレコードタイプのみ、ホストゾーンタグでフィルタ）
    {
      Sid    = "ManageResourceRecordSetsDev"
      Effect = "Allow"
      Action = ["route53:ChangeResourceRecordSets"]
      Resource = "arn:aws:route53:::hostedzone/*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
        StringLike = {
          "route53:ChangeResourceRecordSetsRecordType": [
            "A", "AAAA", "CNAME", "TXT", "MX", "SRV", "PTR", "ALIAS"
          ]
        }
      }
    },

    # NS/SOAレコードの変更を拒否 (開発環境でも禁止)
    {
      Sid    = "DenyNSandSOADev"
      Effect = "Deny"
      Action = ["route53:ChangeResourceRecordSets"]
      Resource = "arn:aws:route53:::hostedzone/*"
      Condition = {
        StringEquals = {
          "route53:ChangeResourceRecordSetsRecordType": ["NS", "SOA"]
        }
      }
    },

    # ヘルスチェック管理（フル管理）
    {
      Sid    = "ManageHealthChecksDev"
      Effect = "Allow"
      Action = [
        "route53:CreateHealthCheck",
        "route53:UpdateHealthCheck",
        "route53:DeleteHealthCheck", # 開発環境は削除可能
        "route53:ChangeTagsForResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    }

    # トラフィックポリシー関連の管理は、必要に応じて追加
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prodタグを持つリソースへの作成・更新のみ）
  # ===================================
  route53_prod_management_statements = [
    # ホストゾーン作成（タグ付与を強制）
    {
      Sid    = "CreateHostedZoneProd"
      Effect = "Allow"
      Action = ["route53:CreateHostedZone"]
      Resource = "*"
      Condition = merge(
        local.required_request_tags,
        {
          StringEquals = {
            "aws:RequestTag/Environment": "prod"
          }
        }
      )
    },

    # ホストゾーン更新（削除除外）
    {
      Sid    = "ManageHostedZoneProd"
      Effect = "Allow"
      Action = [
        "route53:UpdateHostedZoneComment",
        # "route53:DeleteHostedZone", # ❌ 除外
        "route53:ChangeTagsForResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    },
    
    # レコードセット管理（安全なレコードタイプのみ、ホストゾーンタグでフィルタ）
    {
      Sid    = "ManageResourceRecordSetsProd"
      Effect = "Allow"
      Action = ["route53:ChangeResourceRecordSets"]
      Resource = "arn:aws:route53:::hostedzone/*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
        StringLike = {
          "route53:ChangeResourceRecordSetsRecordType": [
            "A", "AAAA", "CNAME", "TXT", "MX", "SRV", "PTR", "ALIAS"
          ]
        }
      }
    },

    # NS/SOAレコードの変更を拒否 (本番環境でも禁止)
    {
      Sid    = "DenyNSandSOAProd"
      Effect = "Deny"
      Action = ["route53:ChangeResourceRecordSets"]
      Resource = "arn:aws:route53:::hostedzone/*"
      Condition = {
        StringEquals = {
          "route53:ChangeResourceRecordSetsRecordType": ["NS", "SOA"]
        }
      }
    },

    # ヘルスチェック管理（削除除外）
    {
      Sid    = "ManageHealthChecksProd"
      Effect = "Allow"
      Action = [
        "route53:CreateHealthCheck",
        "route53:UpdateHealthCheck",
        # "route53:DeleteHealthCheck", # ❌ 除外
        "route53:ChangeTagsForResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  route53_local_management_statements = local.route53_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_route53 = {
    local = concat(
      local.route53_common_statements,
      local.route53_local_management_statements
    ),
    dev = concat(
      local.route53_common_statements,
      local.route53_dev_management_statements
    ),
    prod = concat(
      local.route53_common_statements,
      local.route53_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.route53_common_statements,
      local.route53_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "route53_policy_statement_counts" {
  description = "各環境のRoute53ポリシーのステートメント数"
  value = {
    for env, statements in local.policy_statements_route53 :
    env => length(statements)
  }
}

output "route53_policy_summary" {
  description = "各環境のRoute53ポリシー概要"
  value = {
    local   = "Local環境用 - devタグを持つリソースへのフル管理権限"
    dev     = "開発環境用 - devタグを持つリソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - prodタグを持つリソースへの作成・更新権限のみ（ホストゾーン/ヘルスチェックの削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}