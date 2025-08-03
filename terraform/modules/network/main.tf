# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-vpc-${var.environment}" }
  )
}

# パブリックサブネット
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}" }
  )
}

# プライベートサブネット
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}" }
  )
}

# データベース用サブネットグループ（RDSとAurora共通）
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids  = aws_subnet.private[*].id
  description = "Database subnet group for RDS and Aurora instances"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
    Type        = "Database"
  })
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-igw-${var.environment}" }
  )
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-public-rt-${var.environment}" }
  )
}

# パブリックサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

/*
# アプリケーション用セキュリティグループ（ECS Fargate等で使用）
resource "aws_security_group" "application_sg" {
  name        = "${var.project_name}-app-sg-${var.environment}"
  description = "Security group for application services"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-application-sg-${var.environment}"
    Type = "Application"
  })
}

# データベース用セキュリティグループ
resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Security group for database services"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-database-sg-${var.environment}"
    Type = "Database"
  })
}
*/

# ALB用セキュリティグループ
/*
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPアクセスを許可 (インターネットから)
    description = "Allow HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTPSアクセスを許可 (インターネットから)
    description = "Allow HTTPS from internet"
  }

  # ALBからのアウトバウンドは通常全て許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg-${var.environment}"
    Type = "LoadBalancer"
  })
}
*/

# ALB (Application Load Balancer)
# ※ Fargateサービス用のターゲットグループとリスナーは通常、ECSサービスを定義するモジュールで作成します。
#    ここではALB本体とそれに紐づくSGのみを定義する例です。
/*
resource "aws_lb" "main_alb" {
  name               = "${var.project_name}-main-alb-${var.environment}"
  internal           = false # 外部向けロードバランサー
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id] # 作成したALB用SGをアタッチ
  subnets            = aws_subnet.public.*.id # パブリックサブネットに配置

  # その他のALB設定（必要に応じて）
  enable_deletion_protection = false
  idle_timeout               = 60

  tags = merge(var.tags, {
    Name        = "${var.project_name}-main-alb-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  })
}
*/

data "aws_availability_zones" "available" {
  state = "available"
}