# ===================================
# RDS関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  rds_common_statements = [
    {
      Sid      = "RDSReadAccess"
      Effect   = "Allow"
      Action   = [
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
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  rds_dev_management_statements = [
    # DBインスタンス管理（削除含む）
    {
      Sid    = "DBInstanceManagementDev"
      Effect = "Allow"
      Action = [
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        "rds:DeleteDBInstance",
        "rds:RebootDBInstance",
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-dev-*"
    },
    
    # DBクラスター管理（削除含む）
    {
      Sid    = "DBClusterManagementDev"
      Effect = "Allow"
      Action = [
        # クラスター管理
        "rds:CreateDBCluster",
        "rds:ModifyDBCluster",
        "rds:DeleteDBCluster",
        "rds:StartDBCluster",
        "rds:StopDBCluster",
        # クラスターインスタンスの管理
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        # タグ管理
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-dev-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-dev-*"
      ]
    },
    
    # スナップショット管理（削除含む）
    {
      Sid    = "SnapshotManagementDev"
      Effect = "Allow"
      Action = [
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:CreateDBClusterSnapshot",
        "rds:DeleteDBClusterSnapshot",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:RestoreDBClusterFromSnapshot",
        "rds:CopyDBSnapshot",
        "rds:CopyDBClusterSnapshot",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-dev-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-dev-*"
      ]
    },
    
    # パラメータグループ管理（削除含む）
    {
      Sid    = "ParameterGroupManagementDev"
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
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:pg:${var.project_name}-dev-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-pg:${var.project_name}-dev-*"
      ]
    },
    
    # オプショングループ管理（削除含む）
    {
      Sid    = "OptionGroupManagementDev"
      Effect = "Allow"
      Action = [
        "rds:CreateOptionGroup",
        "rds:ModifyOptionGroup",
        "rds:DeleteOptionGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:og:${var.project_name}-dev-*"
    },
    
    # サブネットグループ管理（削除含む）
    {
      Sid    = "SubnetGroupManagementDev"
      Effect = "Allow"
      Action = [
        "rds:CreateDBSubnetGroup",
        "rds:ModifyDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:${var.project_name}-dev-*"
    },
    
    # イベントサブスクリプション管理（削除含む）
    {
      Sid    = "EventSubscriptionManagementDev"
      Effect = "Allow"
      Action = [
        "rds:CreateEventSubscription",
        "rds:ModifyEventSubscription",
        "rds:DeleteEventSubscription",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:es:${var.project_name}-dev-*"
    },
    
    # IAM PassRole（RDS拡張モニタリング用 - dev-* ロールが対象）
    {
      Sid    = "PassRoleRDSMonitoringDev"
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*-rds-monitoring-role"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "monitoring.rds.amazonaws.com"
          ]
        }
      }
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  rds_prod_management_statements = [
    # DBインスタンス管理（作成・変更のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "DBInstanceManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        # "rds:DeleteDBInstance" は除外
        "rds:RebootDBInstance",
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-prod-*"
    },
    
    # DBクラスター管理（作成・変更のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "DBClusterManagementProd"
      Effect = "Allow"
      Action = [
        # クラスター管理
        "rds:CreateDBCluster",
        "rds:ModifyDBCluster",
        # "rds:DeleteDBCluster" は除外
        "rds:StartDBCluster",
        "rds:StopDBCluster",
        # クラスターインスタンスの管理
        "rds:CreateDBInstance",
        # "rds:DeleteDBInstance" は除外
        # タグ管理
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-prod-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-prod-*"
      ]
    },
    
    # スナップショット管理（作成・復元・コピーのみ - 削除系アクションを意図的に除外）
    {
      Sid    = "SnapshotManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateDBSnapshot",
        # "rds:DeleteDBSnapshot" は除外
        "rds:CreateDBClusterSnapshot",
        # "rds:DeleteDBClusterSnapshot" は除外
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:RestoreDBClusterFromSnapshot",
        "rds:CopyDBSnapshot",
        "rds:CopyDBClusterSnapshot",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-prod-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-prod-*"
      ]
    },
    
    # パラメータグループ管理（削除系アクションを意図的に除外）
    {
      Sid    = "ParameterGroupManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateDBParameterGroup",
        "rds:ModifyDBParameterGroup",
        # "rds:DeleteDBParameterGroup" は除外
        "rds:ResetDBParameterGroup",
        "rds:CreateDBClusterParameterGroup",
        "rds:ModifyDBClusterParameterGroup",
        # "rds:DeleteDBClusterParameterGroup" は除外
        "rds:ResetDBClusterParameterGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = [
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:pg:${var.project_name}-prod-*",
        "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-pg:${var.project_name}-prod-*"
      ]
    },
    
    # オプショングループ管理（削除系アクションを意図的に除外）
    {
      Sid    = "OptionGroupManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateOptionGroup",
        "rds:ModifyOptionGroup",
        # "rds:DeleteOptionGroup" は除外
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:og:${var.project_name}-prod-*"
    },
    
    # サブネットグループ管理（削除系アクションを意図的に除外）
    {
      Sid    = "SubnetGroupManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateDBSubnetGroup",
        "rds:ModifyDBSubnetGroup",
        # "rds:DeleteDBSubnetGroup" は除外
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:${var.project_name}-prod-*"
    },
    
    # イベントサブスクリプション管理（削除系アクションを意図的に除外）
    {
      Sid    = "EventSubscriptionManagementProd"
      Effect = "Allow"
      Action = [
        "rds:CreateEventSubscription",
        "rds:ModifyEventSubscription",
        # "rds:DeleteEventSubscription" は除外
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ]
      Resource = "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:es:${var.project_name}-prod-*"
    },
    
    # IAM PassRole（RDS拡張モニタリング用 - prod-* ロールが対象）
    {
      Sid    = "PassRoleRDSMonitoringProd"
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*-rds-monitoring-role"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "monitoring.rds.amazonaws.com"
          ]
        }
      }
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  rds_local_management_statements = local.rds_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_rds = {
    local = concat(
      local.rds_common_statements,
      local.rds_local_management_statements
    ),
    dev = concat(
      local.rds_common_statements,
      local.rds_dev_management_statements
    ),
    prod = concat(
      local.rds_common_statements,
      local.rds_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.rds_common_statements,
      local.rds_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "rds_policy_statement_counts" {
  description = "各環境のRDSポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_rds :
    env => length(statements)
  }
}

output "rds_policy_summary" {
  description = "各環境のRDSポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*と同等のフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-* リソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prod-* リソースへの作成・変更権限のみ（削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}