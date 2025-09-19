# ECS Cluster Configuration

# Data source for ECS-optimized AMI
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ECS Cluster with container insights enabled
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-${var.project_name}-cluster"
    Environment = var.environment
  }
}

# Launch Template for ECS Tasks
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.environment}-${var.project_name}-template"
  image_id      = data.aws_ami.ecs.id
  instance_type = var.instance_type
  description   = "updated ami"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.ecs_sg_id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
              echo "ECS_CONTAINER_STOP_TIMEOUT=120s" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
              
              # Install SSM agent
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              timedatectl set-timezone America/Phoenix
              EOF
  )

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-${var.project_name}-ecs"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for ECS Instances
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.environment}-${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnets
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "EC2"
  min_size           = var.min_capacity
  max_size           = var.max_capacity
  desired_capacity   = var.desired_count

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.environment}-${var.project_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value              = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Instance Profile for ECS instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.environment}-${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM Role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.environment}-${var.project_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
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
}

# Attach ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
}

# Attach required IAM policies
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ecs_instance_ssm_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.project_name}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn
  cpu                     = var.task_cpu
  memory                  = var.task_memory

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-${var.project_name}"
      image     = var.container_image
      essential = true
      cpu       = var.container_cpu

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      environment = concat(
        [
          {
            name  = "ZOHO_CLIENT_ID"
            value = "1000.HXWZ1C5GBNUCLHNEMK832VXIY1TRBH"
          },
          {
            name  = "REDIS_HOST"
            value = "master.prod-website-redis.sdn2qe.usw1.cache.amazonaws.com"
          },
          {
            name  = "ZOHO_CLIENT_SECRET"
            value = "5be48f15c39e3f501777a91fd7afc67a9035e56d21"
          },
          {
            name  = "GOOGLEREV_API_KEY"
            value = "AIzaSyAjCB7SBaVPQdap5_Kf1RcXfZLZlhLC5Wg"
          },
          {
            name  = "ENVIRONMENT"
            value = "PRODUCTION"
          },
          {
            name  = "MAILGUN_API_KEY"
            value = "5ece34ea6302105998ee2a99cfc95673-2d27312c-fffeca4f"
          },
          {
            name  = "PROTOCOL"
            value = "https://"
          },
          {
            name  = "GQL_TOKEN"
            value = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ..."
          },
          {
            name  = "NEXT_PUBLIC_ENABLE_PRIVATE_CLIENT_MAP"
            value = "true"
          },
          {
            name  = "SMTP2GO_API_KEY"
            value = "api-CB70382F49C343B5A63CCF6490820157"
          },
          {
            name  = "ZOHO_AUTHORIZED_REDIRECT_URI"
            value = "https://gorentals.com/zoho"
          },
          {
            name  = "MAILGUN_MAILER_DOMAIN"
            value = "mailer.gorentals.com"
          },
          {
            name  = "NEXT_PUBLIC_CARCIERGE_API_KEY",
            value = "6768a7fe-0fd7-47bd-9d0b-599dc013ae41"
          },
          {
            name  = "MAILGUN_PRIVATE_CLIENT_DOMAIN"
            value = "privateclient.gorentals.com"
          },
          {
            name  = "NEXT_PUBLIC_MAPBOX_API_KEY"
            value = "pk.eyJ1IjoiZ29yZW50YWxzYXBwcyIsImEiOiJjbWZiNDZ4M2IwNTFmMmtxMzBjc3hyNHViIn0.cPilANxIa-yNUyxCuLpi8g"
          },
          {
            name  = "MAILGUN_DOMAIN"
            value = "reservations.gorentals.com"
          },
          {
            name  = "MAILGUN_GO_RENTALS_DOMAIN"
            value = "gorentals.com"
          },
          {
            name  = "NEXT_PUBLIC_GOOGLE_MAP_API_KEY"
            value = "AIzaSyB49Sh7frZH0oBFq_ISjWi1BtRAwscUfQg"
          },
          {
            name  = "RECAPTCHA_PRIVATE_KEY"
            value = "6LcMoOonAAAAAKeJxy6Y95zdWmxkl0UzJVlARc97"
          },
          {
            name  = "NEXT_PUBLIC_S3_IMG_DOMAIN"
            value = "https://d31ppftgl7y43j.cloudfront.net"
          },
          {
            name  = "REDIS_NOTIFICATION_RECEIVER"
            value = "mygosupport@gorentals.com, harshalp@gorentals.com, shreyanshh@gorentals.com, jayamurugans@gorentals.com"
          },
          {
            name  = "REDIS_PORT"
            value = "6379"
          },
          {
            name  = "NODE_ENV"
            value = "Production"
          },
          {
            name  = "GO_SITE_CMS_API"
            value = "https://api.v2.gosite.gorentals.dnadev.net"
          },
          {
            name  = "NEXT_PUBLIC_RECAPTCHA_SITE_KEY"
            value = "6LcMoOonAAAAAJb1klZbtIP6HuwoSdEhpLeFcbP8"
          },
          {
            name  = "NEXT_PUBLIC_ENVIRONMENT"
            value = "PRODUCTION"
          }
        ],
        var.container_environment
      )

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-${var.project_name}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = "${var.environment}-${var.project_name}"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = var.desired_count
  launch_type                       = "EC2"
  health_check_grace_period_seconds = 60

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50
  enable_execute_command            = true

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.environment}-${var.project_name}"
    container_port   = var.container_port
  }

  deployment_controller {
    type = "ECS"
  }

  tags = {
    Name        = "${var.environment}-${var.project_name}-service"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets           = var.public_subnets

  tags = {
    Name        = "${var.environment}-${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.environment}-${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher            = "200-299"
    port               = "traffic-port"
  }

  # Deregistration delay
  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-${var.project_name}-tg"
    Environment = var.environment
  }
}

# ALB Listener
# HTTP Listener - Redirect to HTTPS
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
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Auto Scaling Configuration
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Scaling Policy
resource "aws_appautoscaling_policy" "cpu_scaling" {
  name               = "${var.environment}-${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory-based Scaling Policy
resource "aws_appautoscaling_policy" "memory_scaling" {
  name               = "${var.environment}-${var.project_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.environment}-${var.project_name}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = 75
  alarm_description  = "ECS service CPU high utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# Low CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
  alarm_name          = "${var.environment}-${var.project_name}-ecs-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = 25
  alarm_description  = "ECS service CPU low utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# High Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.environment}-${var.project_name}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = 75
  alarm_description  = "ECS service memory high utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# Low Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_low" {
  alarm_name          = "${var.environment}-${var.project_name}-ecs-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = 25
  alarm_description  = "ECS service memory low utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.environment}-${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-${var.project_name}-logs"
    Environment = var.environment
  }
}

# Get current AWS region
data "aws_region" "current" {}