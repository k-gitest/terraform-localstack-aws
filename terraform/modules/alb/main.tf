resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
alb_name
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = 60

  tags = merge(var.tags, {
    Name = var.alb_name
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = "ip"  # Fargateの場合はip

  health_check {
    enabled             = each.value.health_check.enabled
    healthy_threshold   = each.value.health_check.healthy_threshold
    interval            = each.value.health_check.interval
    matcher             = each.value.health_check.matcher
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    timeout             = each.value.health_check.timeout
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = each.value.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  # HTTPSが有効な場合はHTTPSにリダイレクト、そうでなければデフォルトターゲットグループに転送
  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = var.default_target_group != "" ? aws_lb_target_group.this[var.default_target_group].arn : null
    }
  }
}

# HTTPSリスナー（オプション）
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.default_target_group != "" ? aws_lb_target_group.this[var.default_target_group].arn : null
  }
}

# パスベースルーティング用のリスナールール（HTTP用）
resource "aws_lb_listener_rule" "http" {
  for_each = var.enable_https ? {} : var.listener_rules

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }

  tags = merge(var.tags, {
    Name = "${var.alb_name}-rule-${each.key}"
  })
}

# パスベースルーティング用のリスナールール（HTTPS用）
resource "aws_lb_listener_rule" "https" {
  for_each = var.enable_https ? var.listener_rules : {}

  listener_arn = aws_lb_listener.https[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  }

  condition {
    path_pattern {
      values = each.value.path_patterns
    }
  }

  tags = merge(var.tags, {
    Name = "${var.alb_name}-rule-${each.key}"
  })
}