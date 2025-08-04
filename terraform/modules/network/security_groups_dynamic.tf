# 動的にデータベースポートのルールを作成する例

# Application → Database (動的にポートを作成)
resource "aws_vpc_security_group_egress_rule" "app_to_database_dynamic" {
  for_each = toset([for port in local.database_ports_unique : tostring(port)])

  security_group_id = aws_security_group.application_sg.id
  description       = "Allow application to communicate with database on port ${each.key}"

  referenced_security_group_id = aws_security_group.database_sg.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"

  tags = {
    Name = "Application-To-Database-${each.key}"
    Port = each.key
  }
}

# Database ← Application (動的にポートを作成)
resource "aws_vpc_security_group_ingress_rule" "database_from_app_dynamic" {
  for_each = toset([for port in local.database_ports_unique : tostring(port)])

  security_group_id = aws_security_group.database_sg.id
  description       = "Allow database to receive traffic from application on port ${each.key}"

  referenced_security_group_id = aws_security_group.application_sg.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"

  tags = {
    Name = "Database-From-Application-${each.key}"
    Port = each.key
  }
}

# 複数の外部CIDRからのアクセスを許可（管理IP等）
variable "management_cidrs" {
  description = "管理用IPアドレスのCIDRブロックリスト"
  type        = list(string)
  default     = []
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_management" {
  for_each = toset(var.management_cidrs)

  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTPS from management CIDR ${each.key}"

  cidr_ipv4   = each.key
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "ALB-Management-${replace(each.key, "/", "-")}"
    CIDR = each.key
  }
}

# 環境別のルール設定
variable "environment_specific_rules" {
  description = "環境ごとの特別なルール設定"
  type = map(object({
    allow_ssh    = bool
    ssh_cidrs    = list(string)
    allow_rdp    = bool
    rdp_cidrs    = list(string)
    debug_ports  = list(number)
  }))
  default = {
    dev = {
      allow_ssh   = true
      ssh_cidrs   = ["10.0.0.0/8"]
      allow_rdp   = false
      rdp_cidrs   = []
      debug_ports = [9229, 5005] # Node.js, Java debug ports
    }
    staging = {
      allow_ssh   = true
      ssh_cidrs   = ["10.0.0.0/8"]
      allow_rdp   = false
      rdp_cidrs   = []
      debug_ports = []
    }
    prod = {
      allow_ssh   = false
      ssh_cidrs   = []
      allow_rdp   = false
      rdp_cidrs   = []
      debug_ports = []
    }
  }
}

# 環境固有のSSHルール
resource "aws_vpc_security_group_ingress_rule" "app_ssh_env" {
  for_each = toset(
    # デフォルト値にすべての属性を含める
    lookup(var.environment_specific_rules, var.environment, {
      allow_ssh = false
      ssh_cidrs = []
      allow_rdp = false
      rdp_cidrs = []
      debug_ports = []
    }).allow_ssh ?
    # こちらも同様にすべての属性を含める
    lookup(var.environment_specific_rules, var.environment, {
      allow_ssh = false
      ssh_cidrs = []
      allow_rdp = false
      rdp_cidrs = []
      debug_ports = []
    }).ssh_cidrs :
    []
  )

  security_group_id = aws_security_group.application_sg.id
  description       = "Allow SSH from ${each.key} in ${var.environment} environment"

  cidr_ipv4   = each.key
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name        = "Application-SSH-${var.environment}"
    Environment = var.environment
    CIDR        = each.key
  }
}

# デバッグポート（開発環境のみ）
resource "aws_vpc_security_group_ingress_rule" "app_debug_ports" {
  for_each = toset([
    for port in lookup(var.environment_specific_rules, var.environment, {
      allow_ssh = false
      ssh_cidrs = []
      allow_rdp = false
      rdp_cidrs = []
      debug_ports = []
    }).debug_ports :
    tostring(port)
  ])

  security_group_id = aws_security_group.application_sg.id
  description       = "Allow debug port ${each.key} in ${var.environment} environment"

  cidr_ipv4   = "10.0.0.0/8" # 内部ネットワークのみ
  from_port   = tonumber(each.key)
  to_port     = tonumber(each.key)
  ip_protocol = "tcp"

  tags = {
    Name        = "Application-Debug-${each.key}"
    Environment = var.environment
    Port        = each.key
    Purpose     = "Debug"
  }
}