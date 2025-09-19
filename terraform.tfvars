# Environment Configuration
environment = "staging"
project_name = "carcierge"
aws_region = "us-west-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
public_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# Services Configuration (5 Carcierge Services)
services = {
  api = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/staging-carcierge-api:latest"
    container_port = 3001
    desired_count = 2
    cpu = 512
    memory = 1024
    health_check_path = "/health"
    environment_variables = {
      NODE_ENV = "staging"
      LOG_LEVEL = "info"
    }
  }
  
  web = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/staging-carcierge-web:latest"
    container_port = 3000
    desired_count = 2
    cpu = 256
    memory = 512
    health_check_path = "/"
    environment_variables = {
      NODE_ENV = "staging"
    }
  }
  
  worker = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/staging-carcierge-worker:latest"
    container_port = 3002
    desired_count = 1
    cpu = 512
    memory = 1024
    health_check_path = "/health"
    environment_variables = {
      NODE_ENV = "staging"
      WORKER_CONCURRENCY = "5"
    }
  }
  
  scheduler = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/staging-carcierge-scheduler:latest"
    container_port = 3003
    desired_count = 1
    cpu = 256
    memory = 512
    health_check_path = "/health"
    environment_variables = {
      NODE_ENV = "staging"
    }
  }
  
  notification = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/staging-carcierge-notification:latest"
    container_port = 3004
    desired_count = 1
    cpu = 256
    memory = 512
    health_check_path = "/health"
    environment_variables = {
      NODE_ENV = "staging"
    }
  }
}

# SSL Certificate (Update with your certificate ARN)
ssl_certificate_arn = "arn:aws:acm:us-west-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# RDS Configuration
rds_config = {
  engine = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100
  database_name = "carcierge"
  username = "carcierge_user"
  backup_retention_period = 7
  backup_window = "03:00-04:00"
  maintenance_window = "sun:04:00-sun:05:00"
  multi_az = false
  storage_encrypted = true
  deletion_protection = false
}

# OpenSearch Configuration
opensearch_config = {
  engine_version = "OpenSearch_2.3"
  instance_type = "t3.small.search"
  instance_count = 1
  volume_type = "gp3"
  volume_size = 20
  dedicated_master_enabled = false
  zone_awareness_enabled = false
  encrypt_at_rest = true
  node_to_node_encryption = true
}

# Redis Configuration
redis_config = {
  node_type = "cache.t3.micro"
  num_cache_nodes = 1
  parameter_group_family = "redis7"
  engine_version = "7.0"
  port = 6379
  maintenance_window = "sun:05:00-sun:06:00"
  snapshot_window = "00:00-01:00"
  snapshot_retention_limit = 5
  automatic_failover_enabled = false
  multi_az_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}

# Common Tags
common_tags = {
  Environment = "staging"
  Project = "carcierge"
  ManagedBy = "terraform"
  Owner = "devops-team"
}