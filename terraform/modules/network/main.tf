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

# プライベートサブネット (必要であれば追加)
/*
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
*/

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


# ECS Fargate用セキュリティグループ
resource "aws_security_group" "ecs_fargate_sg" {
  name        = "${var.project_name}-fargate-sg-${var.environment}"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      security_groups = egress.value.security_groups
    }
  }

  tags = merge(
    var.tags,
    { Name = "${var.project_name}-fargate-sg-${var.environment}" }
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}