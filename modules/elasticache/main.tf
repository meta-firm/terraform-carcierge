# ElastiCache Infrastructure Configuration
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-${var.project_name}-cache-subnet-group"
  subnet_ids = var.private_subnets

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-cache-subnet-group"
  })
}

# Create Redis Parameter Group
resource "aws_elasticache_parameter_group" "redis7" {
  family      = "redis7"
  name        = "${var.environment}-${var.project_name}-redis7-params"
  description = "Custom parameter group for Redis 7.x"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis-params"
  })
}

# ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.environment}-${var.project_name}-redis"
  description         = "Redis cluster for ${var.environment}-${var.project_name}"
  
  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis7.name
  
  num_cache_clusters         = var.num_cache_nodes
  automatic_failover_enabled = var.num_cache_nodes > 1
  multi_az_enabled          = var.num_cache_nodes > 1
  
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_sg_id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  maintenance_window = "sun:05:00-sun:06:00"
  snapshot_window   = "00:00-01:00"
  
  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-redis"
  })
}

/* # High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cache_cpu_high" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = 75
  alarm_description  = "Redis cluster CPU high utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
}

# Low CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cache_cpu_low" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = 40
  alarm_description  = "Redis cluster CPU low utilization"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
}

# High Memory Usage Alarm
resource "aws_cloudwatch_metric_alarm" "cache_memory_high" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = 75
  alarm_description  = "Redis cluster high memory usage"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
}

# Low Memory Usage Alarm
resource "aws_cloudwatch_metric_alarm" "cache_memory_low" {
  alarm_name          = "${var.environment}-${var.project_name}-redis-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = 40
  alarm_description  = "Redis cluster low memory usage"
  alarm_actions      = var.notification_topic_arns

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.main.id
  }
}
*/