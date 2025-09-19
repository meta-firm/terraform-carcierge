# ElastiCache Redis Configuration

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis-subnet-group"
  })
}

# Redis Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family      = var.redis_config.parameter_group_family
  name        = "${var.environment}-${var.project_name}-redis-params"
  description = "Custom parameter group for Redis"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis-params"
  })
}

# ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.environment}-${var.project_name}-redis"
  description         = "Redis cluster for ${var.environment} ${var.project_name}"
  
  node_type            = var.redis_config.node_type
  port                 = var.redis_config.port
  parameter_group_name = aws_elasticache_parameter_group.main.name
  engine_version       = var.redis_config.engine_version
  
  num_cache_clusters         = var.redis_config.num_cache_nodes
  automatic_failover_enabled = var.redis_config.automatic_failover_enabled
  multi_az_enabled          = var.redis_config.multi_az_enabled
  
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_sg_id]
  
  at_rest_encryption_enabled = var.redis_config.at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_config.transit_encryption_enabled
  
  maintenance_window         = var.redis_config.maintenance_window
  snapshot_window           = var.redis_config.snapshot_window
  snapshot_retention_limit  = var.redis_config.snapshot_retention_limit
  
  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis"
  })
}

# CloudWatch Alarms for Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "Redis cluster high CPU utilization"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.main.replication_group_id}-001"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "Redis cluster high memory usage"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.main.replication_group_id}-001"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis-memory-alarm"
  })
}