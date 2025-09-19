# ECS Cluster and Services Configuration

# ECS Cluster with container insights enabled
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.project_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-ecs-cluster"
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-ecs-execution-role"
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-ecs-task-role"
  })
}

# Attach ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for accessing Secrets Manager
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.environment}-${var.project_name}-ecs-secrets-policy"
  description = "Policy for ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}-${var.project_name}-*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-ecs-secrets-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# CloudWatch Log Groups for each service
resource "aws_cloudwatch_log_group" "services" {
  for_each = var.services

  name              = "/ecs/${var.environment}-${var.project_name}-${each.key}"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-logs"
    Service = each.key
  })
}

# Task Definitions for each service
resource "aws_ecs_task_definition" "services" {
  for_each = var.services

  family                   = "${var.environment}-${var.project_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  cpu                     = each.value.cpu
  memory                  = each.value.memory

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-${var.project_name}-${each.key}"
      image     = each.value.container_image
      essential = true

      portMappings = [
        {
          containerPort = each.value.container_port
          protocol      = "tcp"
        }
      ]

      environment = concat(
        [
          {
            name  = "ENVIRONMENT"
            value = var.environment
          },
          {
            name  = "SERVICE_NAME"
            value = each.key
          },
          {
            name  = "RDS_ENDPOINT"
            value = var.rds_endpoint
          },
          {
            name  = "REDIS_ENDPOINT"
            value = var.redis_endpoint
          },
          {
            name  = "OPENSEARCH_ENDPOINT"
            value = var.opensearch_endpoint
          }
        ],
        [for k, v in each.value.environment_variables : {
          name  = k
          value = v
        }]
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.services[each.key].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${each.value.container_port}${each.value.health_check_path} || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-task"
    Service = each.key
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets           = var.public_subnets

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-alb"
  })
}

# Target Groups for each service
resource "aws_lb_target_group" "services" {
  for_each = var.services

  name        = "${var.environment}-${var.project_name}-${each.key}-tg"
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = each.value.health_check_path
    matcher            = "200"
    port               = "traffic-port"
    protocol           = "HTTP"
  }

  deregistration_delay = 30

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-tg"
    Service = each.key
  })
}

# ALB Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-alb-http-listener"
  })
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  # Default action - route to the first service (typically web/api)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[keys(var.services)[0]].arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-alb-https-listener"
  })
}

# ALB Listener Rules for path-based routing
resource "aws_lb_listener_rule" "services" {
  for_each = { for k, v in var.services : k => v if k != keys(var.services)[0] }

  listener_arn = aws_lb_listener.https.arn
  priority     = 100 + index(keys(var.services), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}/*"]
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-rule"
    Service = each.key
  })
}

# ECS Services
resource "aws_ecs_service" "services" {
  for_each = var.services

  name            = "${var.environment}-${var.project_name}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.services[each.key].arn
    container_name   = "${var.environment}-${var.project_name}-${each.key}"
    container_port   = each.value.container_port
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  enable_execute_command = true

  depends_on = [aws_lb_listener.https]

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-service"
    Service = each.key
  })
}

# Auto Scaling Targets
resource "aws_appautoscaling_target" "services" {
  for_each = var.services

  max_capacity       = each.value.desired_count * 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}-scaling-target"
    Service = each.key
  })
}

# Auto Scaling Policies
resource "aws_appautoscaling_policy" "cpu_scaling" {
  for_each = var.services

  name               = "${var.environment}-${var.project_name}-${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "memory_scaling" {
  for_each = var.services

  name               = "${var.environment}-${var.project_name}-${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.services[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.services[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.services[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}