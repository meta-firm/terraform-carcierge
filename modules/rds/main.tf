# RDS Database Configuration

# Generate random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# Store RDS password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${var.environment}-${var.project_name}-rds-password"
  description = "RDS password for ${var.environment} ${var.project_name}"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-secret"
  })
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = var.rds_config.username
    password = random_password.rds_password.result
    engine   = var.rds_config.engine
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = var.rds_config.database_name
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-subnet-group"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.rds_config.engine == "postgres" ? "postgres14" : "mysql8.0"
  name   = "${var.environment}-${var.project_name}-rds-params"

  dynamic "parameter" {
    for_each = var.rds_config.engine == "postgres" ? [
      {
        name  = "shared_preload_libraries"
        value = "pg_stat_statements"
      },
      {
        name  = "log_statement"
        value = "all"
      }
    ] : [
      {
        name  = "innodb_buffer_pool_size"
        value = "{DBInstanceClassMemory*3/4}"
      }
    ]
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-params"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-${var.project_name}-rds"

  # Engine configuration
  engine         = var.rds_config.engine
  engine_version = var.rds_config.engine_version
  instance_class = var.rds_config.instance_class

  # Storage configuration
  allocated_storage     = var.rds_config.allocated_storage
  max_allocated_storage = var.rds_config.max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = var.rds_config.storage_encrypted

  # Database configuration
  db_name  = var.rds_config.database_name
  username = var.rds_config.username
  password = random_password.rds_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.rds_config.backup_retention_period
  backup_window          = var.rds_config.backup_window
  maintenance_window     = var.rds_config.maintenance_window

  # High availability
  multi_az = var.rds_config.multi_az

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection = var.rds_config.deletion_protection
  skip_final_snapshot = !var.rds_config.deletion_protection

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds"
  })
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-monitoring-role"
  })
}

# Attach policy to RDS monitoring role
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.environment}-${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "RDS instance high CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_connection_count" {
  alarm_name          = "${var.environment}-${var.project_name}-rds-connection-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace          = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = "50"
  alarm_description  = "RDS instance high connection count"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-rds-connection-alarm"
  })
}