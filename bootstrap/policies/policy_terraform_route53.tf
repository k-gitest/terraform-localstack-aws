# ===================================
# Route53関連
# ===================================

locals {
  policy_statements_route53 = [
    # 1. 読み取り専用操作
    {
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
    },

    # 2. ホストゾーン作成（タグ必須）
    {
      Effect = "Allow"
      Action = [
        "route53:CreateHostedZone"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:RequestTag/Project": var.project_name
          "aws:RequestTag/ManagedBy": "terraform"
        }
      }
    },

    # 3. ホストゾーン更新・削除（タグフィルタ）
    {
      Effect = "Allow"
      Action = [
        "route53:UpdateHostedZoneComment",
        "route53:DeleteHostedZone",  # prod_restrictionsでDenyされる
        "route53:ChangeTagsForResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
        }
      }
    },

    # 4. レコードセット管理（安全なレコードタイプのみ）
    {
      Effect = "Allow"
      Action = [
        "route53:ChangeResourceRecordSets"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
        }
        StringLike = {
          "route53:ChangeResourceRecordSetsRecordType": [
            "A",
            "AAAA",
            "CNAME",
            "TXT",    # ACM証明書検証用
            "MX",     # メール用
            "SRV"     # サービスディスカバリ用
          ]
        }
      }
    },

    # 5. NS/SOAレコードの変更を拒否
    {
      Effect = "Deny"
      Action = [
        "route53:ChangeResourceRecordSets"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "route53:ChangeResourceRecordSetsRecordType": [
            "NS",   # ネームサーバー
            "SOA"   # Start of Authority
          ]
        }
      }
    }

    # 6. ヘルスチェック作成（タグ必須）
    # {
    #  Effect = "Allow"
    #   Action = [
    #     "route53:CreateHealthCheck"
    #   ]
    #   Resource = "*"
    #   Condition = {
    #     StringEquals = {
    #       "aws:RequestTag/Project": var.project_name
    #       "aws:RequestTag/ManagedBy": "terraform"
    #     }
    #   }
    # },

    # 7. ヘルスチェック更新・削除（タグフィルタ）
    # {
    #   Effect = "Allow"
    #   Action = [
    #     "route53:UpdateHealthCheck",
    #     "route53:DeleteHealthCheck",  # prod_restrictionsでDenyされる
    #     "route53:ChangeTagsForResource"
    #   ]
    #   Resource = "*"
    #   Condition = {
    #     StringEquals = {
    #       "aws:ResourceTag/Project": var.project_name
    #     }
    #   }
    # },

    # 8. トラフィックポリシー管理
    # {
    #   Effect = "Allow"
    #   Action = [
    #     # トラフィックポリシー作成・更新・削除
    #     "route53:CreateTrafficPolicy",
    #     "route53:UpdateTrafficPolicy",
    #     "route53:DeleteTrafficPolicy",  # prod_restrictionsでDenyされる
    #     
        # トラフィックポリシーインスタンス
    #     "route53:CreateTrafficPolicyInstance",
    #     "route53:UpdateTrafficPolicyInstance",
    #     "route53:DeleteTrafficPolicyInstance"  # prod_restrictionsでDenyされる
    #   ]
    #   Resource = [
    #     "arn:aws:route53:::trafficpolicy/*"
    #   ]
    # }
  ]
}