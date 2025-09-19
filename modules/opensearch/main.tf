# OpenSearch Configuration

# OpenSearch Domain
resource "aws_opensearch_domain" "main" {
  domain_name    = "${var.environment}-${var.project_name}-opensearch"
  engine_version = var.opensearch_config.engine_version

  cluster_config {
    instance_type            = var.opensearch_config.instance_type
    instance_count           = var.opensearch_config.instance_count
    dedicated_master_enabled = var.opensearch_config.dedicated_master_enabled
    master_instance_type     = var.opensearch_config.dedicated_master_enabled ? var.opensearch_config.master_instance_type : null
    master_instance_count    = var.opensearch_config.dedicated_master_enabled ? var.opensearch_config.master_instance_count : null
    zone_awareness_enabled   = var.opensearch_config.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.opensearch_config.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = 2
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.opensearch_config.volume_type
    volume_size = var.opensearch_config.volume_size
  }

  vpc_options {
    security_group_ids = [var.opensearch_sg_id]
    subnet_ids         = var.opensearch_config.zone_awareness_enabled ? slice(var.private_subnets, 0, 2) : [var.private_subnets[0]]
  }

  encrypt_at_rest {
    enabled = var.opensearch_config.encrypt_at_rest
  }

  node_to_node_encryption {
    enabled = var.opensearch_config.node_to_node_encryption
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch_password.result
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-opensearch"
  })

  depends_on = [aws_iam_service_linked_role.opensearch]
}

# Generate random password for OpenSearch
resource "random_password" "opensearch_password" {
  length  = 16
  special = true
}

# Store OpenSearch password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "opensearch_password" {
  name        = "${var.environment}-${var.project_name}-opensearch-password"
  description = "OpenSearch password for ${var.environment} ${var.project_name}"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-opensearch-secret"
  })
}

resource "aws_secretsmanager_secret_version" "opensearch_password" {
  secret_id = aws_secretsmanager_secret.opensearch_password.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.opensearch_password.result
    endpoint = aws_opensearch_domain.main.endpoint
    dashboard_endpoint = aws_opensearch_domain.main.dashboard_endpoint
  })
}

# IAM Service Linked Role for OpenSearch
resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service linked role for OpenSearch"
}

# CloudWatch Log Group for OpenSearch
resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/domains/${var.environment}-${var.project_name}-opensearch"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-opensearch-logs"
  })
}

# CloudWatch Log Resource Policy
resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${var.environment}-${var.project_name}-opensearch-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:*"
      }
    ]
  })
}

# CloudWatch Alarms for OpenSearch
resource "aws_cloudwatch_metric_alarm" "opensearch_cluster_status" {
  alarm_name          = "${var.environment}-${var.project_name}-opensearch-cluster-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ClusterStatus.yellow"
  namespace          = "AWS/ES"
  period             = "60"
  statistic          = "Maximum"
  threshold          = "1"
  alarm_description  = "OpenSearch cluster status is red"

  dimensions = {
    DomainName = aws_opensearch_domain.main.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-opensearch-status-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "opensearch_cpu_high" {
  alarm_name          = "${var.environment}-${var.project_name}-opensearch-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace          = "AWS/ES"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "OpenSearch cluster high CPU utilization"

  dimensions = {
    DomainName = aws_opensearch_domain.main.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.project_name}-opensearch-cpu-alarm"
  })
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}