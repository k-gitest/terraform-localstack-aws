# ===================================
# EC2/VPC関連ポリシー定義
# ===================================

locals {
  # ===================================
  # 共通ステートメント（全環境）
  # ===================================
  ec2_common_statements = [
    {
      Sid    = "EC2ReadAccess"
      Effect = "Allow"
      Action = [
        # 読み取り専用操作（Resource制限不可）
        "ec2:Describe*",
        "ec2:GetConsole*"
      ]
      Resource = "*"
    }
  ]

  # ===================================
  # 開発環境専用ステートメント（フル権限）
  # ===================================
  ec2_dev_statements = [
    {
      Sid    = "EC2VPCManagementDev"
      Effect = "Allow"
      Action = [
        # VPC
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        
        # Subnet
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        
        # Route Table
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:ReplaceRoute",
        
        # Internet Gateway
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        
        # NAT Gateway
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        
        # Elastic IP
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        
        # Security Group
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:ModifySecurityGroupRules",
        
        # Network ACL
        "ec2:CreateNetworkAcl",
        "ec2:DeleteNetworkAcl",
        "ec2:CreateNetworkAclEntry",
        "ec2:DeleteNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:ReplaceNetworkAclAssociation",
        
        # VPC Endpoints
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        
        # Tags
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ]
      Resource = "*"
      # 開発環境では柔軟性を優先（タグ制限なし）
    }
  ]

  # ===================================
  # 本番環境専用ステートメント（セキュリティ強化版）
  # ===================================
  ec2_prod_statements = [
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # グループ1: タグ不要な作成系操作
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    {
      Sid    = "EC2VPCCreateNoTagRequired"
      Effect = "Allow"
      Action = [
        # VPC作成（タグは作成時に付与）
        "ec2:CreateVpc",
        "ec2:CreateSubnet",
        "ec2:CreateRouteTable",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateSecurityGroup",
        "ec2:CreateNetworkAcl",
        "ec2:CreateVpcEndpoint",
        
        # Elastic IP割り当て
        "ec2:AllocateAddress"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:RequestedRegion" = "ap-northeast-1"
        }
      }
    },
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # グループ2: タグ付きリソースへの変更操作
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    {
      Sid    = "EC2VPCModifyTagged"
      Effect = "Allow"
      Action = [
        # VPC設定変更
        "ec2:ModifyVpcAttribute",
        "ec2:ModifySubnetAttribute",
        
        # Route操作
        "ec2:CreateRoute",
        "ec2:ReplaceRoute",
        
        # Gateway操作
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        
        # アドレス関連付け
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        
        # Security Group ルール管理
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:ModifySecurityGroupRules",
        
        # Network ACL管理
        "ec2:CreateNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:ReplaceNetworkAclAssociation",
        
        # VPC Endpoint変更
        "ec2:ModifyVpcEndpoint"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Environment" = "prod"
          "aws:ResourceTag/Project"     = var.project_name
          "aws:RequestedRegion"         = "ap-northeast-1"
        }
      }
    },
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # グループ3: タグ管理
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    {
      Sid    = "EC2TagManagement"
      Effect = "Allow"
      Action = [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:RequestedRegion" = "ap-northeast-1"
        }
      }
    }
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 重要: 削除系アクションは完全に除外
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 以下のアクションは意図的にAllowしていません:
    # - ec2:DeleteVpc
    # - ec2:DeleteSubnet
    # - ec2:DeleteRouteTable
    # - ec2:DeleteRoute
    # - ec2:DeleteInternetGateway
    # - ec2:DeleteNatGateway
    # - ec2:ReleaseAddress
    # - ec2:DeleteSecurityGroup
    # - ec2:DeleteNetworkAcl
    # - ec2:DeleteNetworkAclEntry
    # - ec2:DeleteVpcEndpoints
    #
    # 理由:
    # 1. 本番VPCは永続的なリソースであり、削除不要
    # 2. 削除が必要な場合は管理者が手動実行すべき
    # 3. prod_restrictions.tf でも Deny されている（二重保護）
  ]

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_ec2 = {
    # Local環境（LocalStack用）
    local = concat(
      local.ec2_common_statements,
      local.ec2_dev_statements  # 開発環境と同じ権限
    )

    # 開発環境（フル権限）
    dev = concat(
      local.ec2_common_statements,
      local.ec2_dev_statements
    )

    # 本番環境（制限付き - 削除系は完全に除外）
    prod = concat(
      local.ec2_common_statements,
      local.ec2_prod_statements
    )

    # デフォルト（新しい環境追加時のフォールバック）
    default = concat(
      local.ec2_common_statements,
      local.ec2_dev_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================
output "ec2_policy_statement_counts" {
  description = "各環境のEC2ポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_ec2 :
    env => length(statements)
  }
}

output "ec2_policy_summary" {
  description = "各環境のEC2ポリシー概要"
  value = {
    local = "LocalStack用 - フル権限（開発と同等、タグ制限なし）"
    dev   = "開発環境用 - フル権限（VPC/EC2リソースの作成・削除可能、タグ制限なし）"
    prod  = "本番環境用 - 最小権限（作成・変更のみ、削除は完全に除外、タグベース制限あり）"
  }
}

# ===================================
# セキュリティ設計の説明
# ===================================
# 
# 【本番環境のセキュリティ対策】
# 
# 1. タグベースの制限
#    - 変更系アクションは Environment=prod, Project=${var.project_name} 
#      のタグが付いたリソースのみ操作可能
#    - 他プロジェクト/環境のリソースへの誤操作を防止
# 
# 2. 削除系アクションの完全除外
#    - Allowポリシーから削除系を完全に削除
#    - prod_restrictions.tf のDenyと合わせて二重保護
#    - 「削除権限は不要」という意図を明確化
# 
# 3. リージョン制限
#    - ap-northeast-1 以外での操作を禁止
#    - 意図しないリージョンへのデプロイを防止
# 
# 4. Resource = "*" の必要性
#    - EC2/VPC APIの多くはリソースレベルARNをサポートしない
#    - Conditionでタグ制限することで実質的に制限
#    - 作成系はタグ付け前なので Resource = "*" が必須
# 
# 【開発環境との違い】
# 
# - 開発環境: 柔軟性優先（タグ制限なし、削除可能）
# - 本番環境: セキュリティ優先（タグ制限あり、削除不可）