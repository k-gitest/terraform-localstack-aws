# ===================================
# RDS関連ポリシー定義
# ===================================

locals {
  policy_statements_rds = [
    # 1. 読み取り専用操作
    {
      Effect = "Allow"
      Action = [
        # インスタンス情報
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "rds:DescribeDBClusterSnapshots",
        "rds:DescribeDBSnapshots",
        
        # パラメータグループ
        "rds:DescribeDBParameterGroups",
        "rds:DescribeDBParameters",
        "rds:DescribeDBClusterParameterGroups",
        "rds:DescribeDBClusterParameters",
        
        # オプショングループ
        "rds:DescribeOptionGroups",
        "rds:DescribeOptionGroupOptions",
        
        # サブネットグループ
        "rds:DescribeDBSubnetGroups",
        
        # セキュリティグループ
        "rds:DescribeDBSecurityGroups",
        
        # その他
        "rds:DescribeDBEngineVersions",
        "rds:DescribeOrderableDBInstanceOptions",
        "rds:DescribeEventCategories",
        "rds:DescribeEventSubscriptions",
        "rds:DescribeEvents",
        "rds:ListTagsForResource"
      ]
      Resource = "*"  # 読み取りなので全体を許可
    },

    # 2. DBインスタンス管理
    {
      Effect = "Allow"
      Action = [
        # インスタンス作成・変更
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        "rds:DeleteDBInstance",  # prod_restrictionsでDenyされる
        "rds:RebootDBInstance",
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        
        # タグ管理
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-*"
      ]
    },

    # 3. DBクラスター管理（Aurora用）
    {
      Effect = "Allow"
      Action = [
        # クラスター作成・変更
        "rds:CreateDBCluster",
        "rds:ModifyDBCluster",
        "rds:DeleteDBCluster",  # prod_restrictionsでDenyされる
        "rds:StartDBCluster",
        "rds:StopDBCluster",
        
        # クラスターインスタンス
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        
        # タグ管理
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-*"
      ]
    },

    # 4. スナップショット管理
    {
      Effect = "Allow"
      Action = [
        # スナップショット作成・削除
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:CreateDBClusterSnapshot",
        "rds:DeleteDBClusterSnapshot",
        
        # スナップショット復元
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:RestoreDBClusterFromSnapshot",
        
        # スナップショットコピー
        "rds:CopyDBSnapshot",
        "rds:CopyDBClusterSnapshot",
        
        # タグ管理
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-*"
      ]
    },

    # 5. パラメータグループ管理
    {
      Effect = "Allow"
      Action = [
        "rds:CreateDBParameterGroup",
        "rds:ModifyDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:ResetDBParameterGroup",
        
        "rds:CreateDBClusterParameterGroup",
        "rds:ModifyDBClusterParameterGroup",
        "rds:DeleteDBClusterParameterGroup",
        "rds:ResetDBClusterParameterGroup",
        
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:pg:${var.project_name}-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-pg:${var.project_name}-*"
      ]
    },

    # 6. オプショングループ管理
    {
      Effect = "Allow"
      Action = [
        "rds:CreateOptionGroup",
        "rds:ModifyOptionGroup",
        "rds:DeleteOptionGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:og:${var.project_name}-*"
      ]
    },

    # 7. サブネットグループ管理
    {
      Effect = "Allow"
      Action = [
        "rds:CreateDBSubnetGroup",
        "rds:ModifyDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:${var.project_name}-*"
      ]
    },

    # 8. イベントサブスクリプション管理
    {
      Effect = "Allow"
      Action = [
        "rds:CreateEventSubscription",
        "rds:ModifyEventSubscription",
        "rds:DeleteEventSubscription",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:es:${var.project_name}-*"
      ]
    },

    # 9. IAM PassRole（RDS拡張モニタリング用）
    {
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*-rds-monitoring-role"
      ]
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "monitoring.rds.amazonaws.com"
          ]
        }
      }
    }
  ]
}