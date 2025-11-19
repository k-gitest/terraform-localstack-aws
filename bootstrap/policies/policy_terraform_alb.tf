# ===================================
# ALB/ELB関連ポリシー定義
# ===================================

locals {
  policy_statements_alb = [
    # 1. 読み取り専用操作
    {
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
      Resource = "*"  # 読み取りなので全体を許可
    },

    # 2. ロードバランサー管理
    {
      Effect = "Allow"
      Action = [
        # ロードバランサー作成・削除
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",  # prod_restrictionsでDenyされる
        
        # ロードバランサー設定
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        
        # タグ管理
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-*"
      ]
    },

    # 3. ターゲットグループ管理
    {
      Effect = "Allow"
      Action = [
        # ターゲットグループ作成・削除
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",  # prod_restrictionsでDenyされる
        
        # ターゲットグループ設定
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        
        # ターゲット登録・解除
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        
        # タグ管理
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-*"
      ]
    },

    # 4. リスナー管理
    {
      Effect = "Allow"
      Action = [
        # リスナー作成・削除
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        
        # リスナー設定
        "elasticloadbalancing:ModifyListener",
        
        # SSL証明書管理
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/${var.project_name}-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/${var.project_name}-*"
      ]
    },

    # 5. リスナールール管理
    {
      Effect = "Allow"
      Action = [
        # ルール作成・削除
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        
        # ルール設定
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:SetRulePriorities",
        
        # タグ管理
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/${var.project_name}-*",
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/${var.project_name}-*"
      ]
    },

    # 6. ターゲット登録時の追加権限（EC2/ECS用）
    {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-*"
      ]
      Condition = {
        StringEquals = {
          # 特定のターゲットタイプのみ許可
          "elasticloadbalancing:TargetType": [
            "instance",  # EC2インスタンス
            "ip"         # ECS Fargate
          ]
        }
      }
    }
  ]
}