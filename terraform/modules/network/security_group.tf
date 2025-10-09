# ==================================================
# セキュリティグループの定義
# ==================================================

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg-${var.environment}"
    Type = "ALB"
  })
}

# Application (Fargate) Security Group
resource "aws_security_group" "application_sg" {
  name        = "${var.project_name}-app-sg-${var.environment}"
  description = "Security group for application services (Fargate)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-sg-${var.environment}"
    Type = "Application"
  })
}

# Database Security Group (RDS & Aurora 共用)
resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Security group for database services (RDS/Aurora)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-sg-${var.environment}"
    Type = "Database"
  })
}

# S3用VPC Endpoint Security Group（オプション）
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project_name}-vpce-sg-${var.environment}"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpce-sg-${var.environment}"
    Type = "VPC-Endpoint"
  })
}

# ==================================================
# ALB セキュリティグループルール
# ==================================================

# ALB インバウンドルール: HTTP
resource "aws_vpc_security_group_ingress_rule" "alb_http_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP from internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = {
    Name = "ALB-HTTP-Ingress"
  }
}

# ALB インバウンドルール: HTTPS
resource "aws_vpc_security_group_ingress_rule" "alb_https_ingress" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTPS from internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "ALB-HTTPS-Ingress"
  }
}

# ALB アウトバウンドルール: Application への転送
resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow ALB to communicate with application"

  referenced_security_group_id = aws_security_group.application_sg.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"

  tags = {
    Name = "ALB-To-Application"
  }
}

# ==================================================
# Application (Fargate) セキュリティグループルール
# ==================================================

# Application インバウンドルール: ALB からの接続
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id = aws_security_group.application_sg.id
  description       = "Allow application to receive traffic from ALB"

  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"

  tags = {
    Name = "Application-From-ALB"
  }
}

# Application アウトバウンドルール: PostgreSQL
resource "aws_vpc_security_group_egress_rule" "app_to_postgres" {
  security_group_id = aws_security_group.application_sg.id
  description       = "Allow application to communicate with PostgreSQL"

  referenced_security_group_id = aws_security_group.database_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = {
    Name = "Application-To-PostgreSQL"
  }
}

# Application アウトバウンドルール: MySQL
resource "aws_vpc_security_group_egress_rule" "app_to_mysql" {
  security_group_id = aws_security_group.application_sg.id
  description       = "Allow application to communicate with MySQL"

  referenced_security_group_id = aws_security_group.database_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"

  tags = {
    Name = "Application-To-MySQL"
  }
}

# Application アウトバウンドルール: HTTPS（インターネット）
resource "aws_vpc_security_group_egress_rule" "app_https_egress" {
  # !!! 🚨 セキュリティリスク警告 🚨 !!!
  # cidr_ipv4 = "0.0.0.0/0" は、ランサムウェア等の攻撃者がDBから窃取したデータを
  # 外部のC&Cサーバーへ転送するための「黄金の出口」となります。
  # この設定が有効な場合、転送が正規のHTTPS通信として処理されるため、
  # ネットワーク監視による不正データ持ち出しの検知が極めて困難になります。
  # → 実装する場合、このルールを削除し、AWSサービスへの接続はVPCエンドポイント (VPCE) に切り替えること。
  # → 外部APIへの接続は、特定のIPレンジ/FQDNに限定したプロキシ経由とすること。
  security_group_id = aws_security_group.application_sg.id
  description       = "Allow HTTPS to internet (S3, external APIs)"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "Application-HTTPS-Egress"
  }
}

# Application アウトバウンドルール: HTTP（インターネット）
resource "aws_vpc_security_group_egress_rule" "app_http_egress" {
  # !!! 🚨 セキュリティリスク警告 🚨 !!!
  # HTTP (ポート80) のアウトバウンドを 0.0.0.0/0 で許可することは、マルウェアのダウンロードや
  # コマンド＆コントロール（C2）通信の経路を提供します。
  # HTTPS (443) と同様、実装時に、この設定は可能な限り削除し、特定の宛先に限定します
  security_group_id = aws_security_group.application_sg.id
  description       = "Allow HTTP to internet (external APIs)"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  tags = {
    Name = "Application-HTTP-Egress"
  }
}

# ==================================================
# Database セキュリティグループルール
# ==================================================

# Database インバウンドルール: PostgreSQL
resource "aws_vpc_security_group_ingress_rule" "db_from_app_postgres" {
  security_group_id = aws_security_group.database_sg.id
  description       = "Allow PostgreSQL from application"

  referenced_security_group_id = aws_security_group.application_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = {
    Name = "Database-PostgreSQL-From-Application"
  }
}

# Database インバウンドルール: MySQL
resource "aws_vpc_security_group_ingress_rule" "db_from_app_mysql" {
  security_group_id = aws_security_group.database_sg.id
  description       = "Allow MySQL from application"

  referenced_security_group_id = aws_security_group.application_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"

  tags = {
    Name = "Database-MySQL-From-Application"
  }
}

# ==================================================
# VPC Endpoint セキュリティグループルール
# ==================================================

# VPC Endpoint インバウンドルール: Application からのHTTPS
resource "aws_vpc_security_group_ingress_rule" "vpce_from_app" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  description       = "Allow VPC endpoint to receive HTTPS from application"

  referenced_security_group_id = aws_security_group.application_sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"

  tags = {
    Name = "VPC-Endpoint-From-Application"
  }
}

# ==================================================
# 条件付きルール（環境に応じて適用）
# ==================================================

# 開発環境でのSSHアクセス（必要に応じて）
resource "aws_vpc_security_group_ingress_rule" "app_ssh_dev" {
  count = var.environment == "dev" ? 1 : 0

  security_group_id = aws_security_group.application_sg.id
  description       = "Allow SSH for development"

  cidr_ipv4   = var.dev_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "Application-SSH-Dev"
  }
}