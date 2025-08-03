# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-exec-role-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Policy for ECS Task Execution Role (e.g., CloudWatch Logs, ECR Pull)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Or more restrictive policy if preferred
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Policy for Secrets Manager and Systems Manager Parameter Store access (if secrets are used)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_ssm_secrets" {
  count      = length(var.secrets) > 0 ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # Or a more restrictive custom policy
}

# IAM Role for ECS Task (Application-specific permissions)
# This role grants permissions that the application running inside the container needs.
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-task-role-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  })
}

# --- CloudWatch Log Group for the Service ---
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = var.log_group_name != "" ? var.log_group_name : "/ecs/${var.project_name}/${var.service_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name        = var.log_group_name != "" ? var.log_group_name : "${var.project_name}-${var.service_name}-${var.environment}-logs"
    Environment = var.environment
    Project     = var.project_name
  })
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family != "" ? var.task_family : "${var.project_name}-${var.service_name}-${var.environment}"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  network_mode             = "awsvpc" # Fargate requires awsvpc
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Application-specific role

  container_definitions = jsonencode([
    {
      name        = var.container_name != "" ? var.container_name : "${var.service_name}-container"
      image       = var.container_image
      cpu         = var.cpu
      memory      = var.memory
      essential   = true
      command     = var.container_command
      entryPoint  = var.container_entry_point
      environment = var.environment_variables
      secrets     = var.secrets
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port # Not applicable for Fargate, but required in definition
          protocol      = var.container_protocol
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.log_stream_prefix
        }
      }
      # ECS Exec configuration
      linuxParameters = {
        initProcessEnabled = var.enable_execute_command
      }
    }
  ])

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.service_name}-${var.environment}-task"
    Environment = var.environment
    Project     = var.project_name
  })
}

# ALBターゲットグループ
resource "aws_lb_target_group" "this" {
  count = var.enable_load_balancer ? 1 : 0 # ロードバランサー有効時のみ作成

  name                 = "${var.project_name}-${var.service_name}-${var.environment}-tg"
  port                 = var.container_port
  protocol             = "HTTP" # または HTTPS
  vpc_id               = var.vpc_id # ルートからVPC IDを受け取る変数が必要です
  target_type          = "ip"       # FargateはIPターゲット

  health_check {
    path                = var.health_check_path # 例: "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.service_name}-${var.environment}-tg"
    Environment = var.environment
    Project     = var.project_name
  })
}

# --- ECS Service ---
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.load_balancer_container_name != "" ? var.load_balancer_container_name : (var.container_name != "" ? var.container_name : "${var.service_name}-container")
      container_port   = var.load_balancer_container_port != 0 ? var.load_balancer_container_port : var.container_port
    }
  }

  # Health check grace period for services behind a load balancer
  health_check_grace_period_seconds = var.enable_load_balancer ? var.health_check_grace_period_seconds : 0

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = var.enable_deployment_circuit_breaker
    rollback = var.deployment_circuit_breaker_rollback
  }

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  # Service Discovery
  dynamic "service_registries" {
    for_each = var.enable_service_discovery && var.service_discovery_namespace_id != "" && var.service_discovery_service_name != "" ? [1] : []
    content {
      registry_arn   = aws_service_discovery_service.this[0].arn
      container_name = var.container_name != "" ? var.container_name : "${var.service_name}-container"
      container_port = var.container_port
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.service_name}-${var.environment}-service"
    Environment = var.environment
    Project     = var.project_name
  })

  # Ensure the log group is created before the task definition
  depends_on = [
    aws_cloudwatch_log_group.ecs_log_group
  ]
}

# Ingress Rule: Allow traffic from ALB to Fargate (if ALB is enabled)
/*
resource "aws_security_group_rule" "fargate_ingress_from_alb" {
  count = var.alb_security_group_id != null ? 1 : 0 # ALB SG IDが渡された場合のみ作成

  type                     = "ingress"
  from_port                = var.container_port # Fargateサービスが公開するポート
  to_port                  = var.container_port
  protocol                 = var.container_protocol
  security_group_id        = var.security_groups[0] # Fargateサービスにアタッチされる最初のSGのID
  source_security_group_id = var.alb_security_group_id
  description              = "Allow inbound from ALB on port ${var.container_port}"
}
*/

# Egress Rule: Allow outbound traffic to Database
/*
resource "aws_security_group_rule" "fargate_egress_to_db" {
  type                     = "egress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  security_group_id        = var.security_groups[0] # Fargateサービスにアタッチされる最初のSGのID
  source_security_group_id = var.database_security_group_id
  description              = "Allow outbound to DB on port ${var.database_port}"
}
*/

# Egress Rule: Allow outbound traffic to Public Internet (for ECR, CloudWatch Logs, updates, etc.)
# Consider tightening this if VPC Endpoints are fully utilized.
/*
resource "aws_security_group_rule" "fargate_egress_to_public_internet" {
  count = var.enable_public_internet_egress ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.security_groups[0] # Fargateサービスにアタッチされる最初のSGのID
  description       = "Allow all outbound traffic to public internet"
}
*/

# --- Auto Scaling Configuration ---
resource "aws_appautoscaling_target" "ecs_service_target" {
  count = var.enable_autoscaling ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "ecs_cpu_scaling_policy" {
  count = var.enable_autoscaling ? 1 : 0

  name              = "${var.service_name}-cpu-scaling-policy"
  service_namespace = "ecs"
  resource_id       = aws_appautoscaling_target.ecs_service_target[0].resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type       = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
    scale_in_cooldown  = 300 # seconds
    scale_out_cooldown = 300 # seconds
  }
}

resource "aws_appautoscaling_policy" "ecs_memory_scaling_policy" {
  count = var.enable_autoscaling ? 1 : 0

  name              = "${var.service_name}-memory-scaling-policy"
  service_namespace = "ecs"
  resource_id       = aws_appautoscaling_target.ecs_service_target[0].resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type       = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.target_memory_utilization
    scale_in_cooldown  = 300 # seconds
    scale_out_cooldown = 300 # seconds
  }
}

# --- Service Discovery (Cloud Map) ---
resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery && var.service_discovery_namespace_id != "" && var.service_discovery_service_name != "" ? 1 : 0

  name        = var.service_discovery_service_name
  namespace_id = var.service_discovery_namespace_id
  description = "Service Discovery for ${var.service_name} ECS service"

  dns_config {
    namespace_id   = var.service_discovery_namespace_id
    routing_policy = "MULTIVALUE" # or "WEIGHTED"
    dns_records {
      type = "A"
      ttl  = 10
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.service_discovery_service_name}-${var.environment}-sd"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Data source to get current AWS region
data "aws_region" "current" {}