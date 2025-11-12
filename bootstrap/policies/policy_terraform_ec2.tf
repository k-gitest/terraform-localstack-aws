# ===================================
# EC2/VPC関連ポリシー定義
# ===================================

locals {
  policy_statements_ec2 = [
    # 読み取り専用操作
    {
      Effect = "Allow"
      Action = [
        "ec2:Describe*",
        "ec2:GetConsole*"
      ]
      Resource = "*"
    },
    
    # 書き込み操作
    {
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
    }
  ]
}